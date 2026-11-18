package main

import (
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"math/big"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	_ "modernc.org/sqlite"
)

// Guest profiles (plan of 17 Nov, PR 3: the profile "in the shadow"). The
// phone asks the server for an identity (a number and a long random key; the
// server keeps only the key's hash), brings its progress over once (cut to
// the caps, sim/profile.lua import) and then sends a copy of its profile at
// every start and match end. For now the phone's profile is the one that
// counts: the server keeps its own (the import) and the latest copy, and
// writes every change in the register, so for a few days it shows on the VPS
// whether everything comes back. The profile travels and is kept as the
// recipes' text (sim/replay.lua write/read: pure data).
//
// SQLite in one file (-profili, on the VPS /var/lib/megablast/megablast.db),
// pure Go driver (no cgo: the VPS build stays the same). The VPS copies it
// every night with the rest of its data and sends it to Cloudflare R2
// (choice 3B, tools/vps/installa.sh, megablast-copia).

// ProfileDB is the database file (main.go, -profili); empty: no profiles
var ProfileDB = ""

const (
	profileMax = 256 << 10
	// new profiles from one address in an hour (a phone makes one, once)
	profileNewPerHour = 10
)

type Accounts struct {
	db *sql.DB
	mu sync.Mutex // one writer at a time (SQLite)

	nmu    sync.Mutex
	births map[string][]time.Time
}

func OpenAccounts(path string) (*Accounts, error) {
	if dir := filepath.Dir(path); dir != "" {
		if err := os.MkdirAll(dir, 0o700); err != nil {
			return nil, err
		}
	}
	db, err := sql.Open("sqlite", "file:"+path+"?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_pragma=foreign_keys(1)")
	if err != nil {
		return nil, err
	}
	db.SetMaxOpenConns(1)
	_, err = db.Exec(`
CREATE TABLE IF NOT EXISTS giocatori (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	chiave TEXT NOT NULL,
	nome TEXT NOT NULL,
	profilo TEXT NOT NULL,
	rev INTEGER NOT NULL,
	importato INTEGER NOT NULL DEFAULT 0,
	copia TEXT,
	copia_rev INTEGER NOT NULL DEFAULT 0,
	copia_quando INTEGER,
	creato INTEGER NOT NULL,
	aggiornato INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS registro (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	giocatore INTEGER NOT NULL REFERENCES giocatori(id),
	quando INTEGER NOT NULL,
	tipo TEXT NOT NULL,
	dati TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS registro_giocatore ON registro(giocatore, id);`)
	if err != nil {
		db.Close()
		return nil, err
	}
	return &Accounts{db: db, births: map[string][]time.Time{}}, nil
}

func (a *Accounts) Close() error { return a.db.Close() }

// ProfileSummary: a few numbers of a profile (server/worker.lua, summary)
type ProfileSummary struct {
	Level     int    `json:"livello"`
	XP        int    `json:"xp"`
	Scaglie   int    `json:"scaglie"`
	Ossidiana int    `json:"ossidiana"`
	Pieces    int    `json:"pezzi"`
	Stars     int    `json:"stelle"`
	Profile   string `json:"profilo,omitempty"`
	Err       string `json:"err,omitempty"`
}

func (s ProfileSummary) String() string {
	return fmt.Sprintf("livello %d, %d Scaglie, %d Ossidiana, %d pezzi, %d stelle", s.Level, s.Scaglie, s.Ossidiana, s.Pieces, s.Stars)
}

func profileLua(f string, args map[string]string) (ProfileSummary, error) {
	b := &Batch{}
	b.Cmd(f, 0, nil)
	keys := make([]string, 0, len(args))
	for k := range args {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	for _, k := range keys {
		b.Str(k, args[k])
	}
	b.End()
	res, err := callUtil(b)
	if err != nil {
		return ProfileSummary{}, err
	}
	var s ProfileSummary
	if err := json.Unmarshal(res.Head, &s); err != nil {
		return s, err
	}
	if s.Err != "" {
		return s, errors.New(s.Err)
	}
	return s, nil
}

func hashKey(key string) string {
	h := sha256.Sum256([]byte(key))
	return hex.EncodeToString(h[:])
}

func randomName() string {
	n, err := rand.Int(rand.Reader, big.NewInt(10000))
	if err != nil {
		return "Diavoletto"
	}
	return fmt.Sprintf("Diavoletto %04d", n.Int64())
}

// Account: a row of giocatori as the phone gets it
type Account struct {
	ID      int64  `json:"id"`
	Key     string `json:"chiave,omitempty"`
	Name    string `json:"nome"`
	Rev     int64  `json:"rev"`
	Profile string `json:"profilo"`
}

// New creates a profile, from the phone's progress when text isn't empty.
func (a *Accounts) New(text string) (Account, ProfileSummary, error) {
	name := randomName()
	s, err := profileLua("profile_new", map[string]string{"name": name, "text": text})
	if err != nil {
		return Account{}, s, err
	}
	raw := make([]byte, 24)
	if _, err := rand.Read(raw); err != nil {
		return Account{}, s, err
	}
	key := hex.EncodeToString(raw)
	now := time.Now().Unix()
	imported := 0
	kind := "nascita"
	if text != "" {
		imported, kind = 1, "import"
	}
	a.mu.Lock()
	defer a.mu.Unlock()
	tx, err := a.db.Begin()
	if err != nil {
		return Account{}, s, err
	}
	defer tx.Rollback()
	res, err := tx.Exec(`INSERT INTO giocatori (chiave, nome, profilo, rev, importato, creato, aggiornato) VALUES (?, ?, ?, 1, ?, ?, ?)`,
		hashKey(key), name, s.Profile, imported, now, now)
	if err != nil {
		return Account{}, s, err
	}
	id, err := res.LastInsertId()
	if err != nil {
		return Account{}, s, err
	}
	if err := ledger(tx, id, now, kind, s); err != nil {
		return Account{}, s, err
	}
	if err := tx.Commit(); err != nil {
		return Account{}, s, err
	}
	return Account{ID: id, Key: key, Name: name, Rev: 1, Profile: s.Profile}, s, nil
}

func ledger(tx *sql.Tx, id, now int64, kind string, s ProfileSummary) error {
	s.Profile = ""
	data, _ := json.Marshal(s)
	_, err := tx.Exec(`INSERT INTO registro (giocatore, quando, tipo, dati) VALUES (?, ?, ?, ?)`, id, now, kind, string(data))
	return err
}

var errNoProfile = errors.New("profilo sconosciuto o chiave sbagliata")

// Get returns the profile of id if key is its key.
func (a *Accounts) Get(id int64, key string) (Account, error) {
	var acc Account
	var hash string
	err := a.db.QueryRow(`SELECT id, chiave, nome, rev, profilo FROM giocatori WHERE id = ?`, id).Scan(&acc.ID, &hash, &acc.Name, &acc.Rev, &acc.Profile)
	if errors.Is(err, sql.ErrNoRows) {
		return acc, errNoProfile
	}
	if err != nil {
		return acc, err
	}
	if subtle.ConstantTimeCompare([]byte(hash), []byte(hashKey(key))) != 1 {
		return Account{}, errNoProfile
	}
	return acc, nil
}

// Copy keeps the phone's copy of the profile; the register gets a row when
// its numbers changed since the last copy. Returns whether they changed.
func (a *Accounts) Copy(id int64, key, text string) (ProfileSummary, bool, error) {
	if _, err := a.Get(id, key); err != nil {
		return ProfileSummary{}, false, err
	}
	s, err := profileLua("profile_summary", map[string]string{"text": text})
	if err != nil {
		return s, false, err
	}
	now := time.Now().Unix()
	a.mu.Lock()
	defer a.mu.Unlock()
	tx, err := a.db.Begin()
	if err != nil {
		return s, false, err
	}
	defer tx.Rollback()
	var last sql.NullString
	err = tx.QueryRow(`SELECT dati FROM registro WHERE giocatore = ? AND tipo = 'copia' ORDER BY id DESC LIMIT 1`, id).Scan(&last)
	if err != nil && !errors.Is(err, sql.ErrNoRows) {
		return s, false, err
	}
	if _, err := tx.Exec(`UPDATE giocatori SET copia = ?, copia_rev = copia_rev + 1, copia_quando = ? WHERE id = ?`, text, now, id); err != nil {
		return s, false, err
	}
	data, _ := json.Marshal(ProfileSummary{Level: s.Level, XP: s.XP, Scaglie: s.Scaglie, Ossidiana: s.Ossidiana, Pieces: s.Pieces, Stars: s.Stars})
	changed := !last.Valid || last.String != string(data)
	if changed {
		if err := ledger(tx, id, now, "copia", s); err != nil {
			return s, false, err
		}
	}
	return s, changed, tx.Commit()
}

// Who sends the request: the address Caddy puts in X-Forwarded-For when the
// request comes from the machine itself, otherwise the connection's.
func requestIP(r *http.Request) string {
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		host = r.RemoteAddr
	}
	if ip := net.ParseIP(host); ip != nil && ip.IsLoopback() {
		if f := r.Header.Get("X-Forwarded-For"); f != "" {
			return strings.TrimSpace(strings.Split(f, ",")[0])
		}
	}
	return host
}

func (a *Accounts) allowBirth(ip string, now time.Time) bool {
	a.nmu.Lock()
	defer a.nmu.Unlock()
	kept := a.births[ip][:0]
	for _, t := range a.births[ip] {
		if now.Sub(t) < time.Hour {
			kept = append(kept, t)
		}
	}
	if len(kept) >= profileNewPerHour {
		a.births[ip] = kept
		return false
	}
	a.births[ip] = append(kept, now)
	return true
}

// The phone says who it is with the header "Authorization: Profilo <id>.<chiave>"
// (never in the address: Caddy's access log writes the addresses).
func authProfile(r *http.Request) (int64, string, bool) {
	v, ok := strings.CutPrefix(r.Header.Get("Authorization"), "Profilo ")
	if !ok {
		return 0, "", false
	}
	ids, key, ok := strings.Cut(v, ".")
	id, err := strconv.ParseInt(ids, 10, 64)
	if !ok || err != nil || id <= 0 || len(key) == 0 || len(key) > 128 {
		return 0, "", false
	}
	return id, key, true
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(v)
}

// /profilo/nuovo, /profilo, /profilo/copia (docs/server.md, "Profili ospite")
func (s *Server) handleProfile(w http.ResponseWriter, r *http.Request) {
	a := s.accounts
	if a == nil {
		http.Error(w, "profili spenti", http.StatusServiceUnavailable)
		return
	}
	if r.Method != http.MethodPost {
		http.Error(w, "solo POST", http.StatusMethodNotAllowed)
		return
	}
	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, profileMax))
	if err != nil {
		http.Error(w, "profilo troppo grande", http.StatusRequestEntityTooLarge)
		return
	}
	who := clean(r.URL.Query().Get("p"))
	switch r.URL.Path {
	case "/profilo/nuovo":
		ip := requestIP(r)
		if !a.allowBirth(ip, time.Now()) {
			log.Printf("profili: nuovo da %s (%s) rifiutato, troppi in un'ora", who, ip)
			http.Error(w, "troppi profili nuovi", http.StatusTooManyRequests)
			return
		}
		acc, sum, err := a.New(string(body))
		if err != nil {
			log.Printf("profili: nuovo da %s non creato: %v", who, err)
			http.Error(w, "profilo non creato", http.StatusBadRequest)
			return
		}
		if len(body) > 0 {
			log.Printf("profili: %d nato da %s, importato: %s", acc.ID, who, sum)
		} else {
			log.Printf("profili: %d nato da %s, da zero", acc.ID, who)
		}
		writeJSON(w, acc)
	case "/profilo":
		id, key, ok := authProfile(r)
		acc, err := a.Get(id, key)
		if !ok || err != nil {
			http.Error(w, errNoProfile.Error(), http.StatusUnauthorized)
			return
		}
		writeJSON(w, acc)
	case "/profilo/copia":
		id, key, ok := authProfile(r)
		if !ok {
			http.Error(w, errNoProfile.Error(), http.StatusUnauthorized)
			return
		}
		sum, changed, err := a.Copy(id, key, string(body))
		if errors.Is(err, errNoProfile) {
			http.Error(w, err.Error(), http.StatusUnauthorized)
			return
		}
		if err != nil {
			log.Printf("profili: copia di %d da %s rifiutata: %v", id, who, err)
			http.Error(w, "copia rifiutata", http.StatusBadRequest)
			return
		}
		if changed {
			log.Printf("profili: copia di %d da %s: %s", id, who, sum)
		}
		writeJSON(w, map[string]bool{"ok": true})
	default:
		http.NotFound(w, r)
	}
}
