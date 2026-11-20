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

// Guest profiles (plan of 17 Nov). The phone asks the server for an identity
// (a number and a long random key; the server keeps only the key's hash) and
// brings its progress over once (cut to the caps, sim/profile.lua import).
// From PR 4 the server's profile is the one that counts: the phone sends what
// it did (sim/progress.lua: a purchase, the ZAINO, a match...), the server
// does it with the same rules and answers its profile, which the phone takes.
// Every request goes into the register. The profile travels and is kept as
// the recipes' text (sim/replay.lua write/read: pure data).
//
// SQLite in one file (-profili, on the VPS /var/lib/megablast/megablast.db),
// pure Go driver (no cgo: the VPS build stays the same). The VPS copies it
// every night with the rest of its data and sends it to Cloudflare R2
// (choice 3B, tools/vps/installa.sh, megablast-copia).

// ProfileDB is the database file (main.go, -profili); empty: no profiles
var ProfileDB = ""

const (
	// a profile, or the actions of a request (up to 5 matches with their recipes)
	profileMax = 8 << 20
	// new profiles from one address in an hour (a phone makes one, once)
	profileNewPerHour = 10
)

type Accounts struct {
	db *sql.DB
	mu sync.Mutex // one writer at a time (SQLite)

	nmu    sync.Mutex
	births map[string][]time.Time
	// the recovery codes tried, per address (recovery.go)
	tries map[string][]time.Time
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
	// PR 4: whether the server already owns the profile (before, the phone's
	// latest copy counted: it becomes the server's at the first request), and
	// the number of the last action of the phone done
	// PR 6: the fingerprint of the recovery code and the block from the panel
	for _, col := range []string{"padrone INTEGER NOT NULL DEFAULT 0", "ultima INTEGER NOT NULL DEFAULT 0",
		"codice TEXT", "bloccato INTEGER NOT NULL DEFAULT 0"} {
		if _, err := db.Exec(`ALTER TABLE giocatori ADD COLUMN ` + col); err != nil && !strings.Contains(err.Error(), "duplicate column") {
			db.Close()
			return nil, err
		}
	}
	if _, err := db.Exec(`CREATE UNIQUE INDEX IF NOT EXISTS giocatori_codice ON giocatori(codice)`); err != nil {
		db.Close()
		return nil, err
	}
	return &Accounts{db: db, births: map[string][]time.Time{}, tries: map[string][]time.Time{}}, nil
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
	// profile_do: the last action done and what each one did ("compra,no firma")
	Last int64  `json:"ultima,omitempty"`
	Done string `json:"fatte,omitempty"`
	// the numbers of the matches replayed and not paid (server/worker.lua profile_do)
	Refused []int64 `json:"rifiutate,omitempty"`
	Err     string  `json:"err,omitempty"`
}

func (s ProfileSummary) String() string {
	return fmt.Sprintf("livello %d, %d Scaglie, %d Ossidiana, %d pezzi, %d stelle", s.Level, s.Scaglie, s.Ossidiana, s.Pieces, s.Stars)
}

func profileLua(f string, args map[string]string) (ProfileSummary, error) {
	s, _, err := profileCall(f, args)
	return s, err
}

// profileCall: like profileLua, with the raws of the answer too
func profileCall(f string, args map[string]string) (ProfileSummary, [][]byte, error) {
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
		return ProfileSummary{}, nil, err
	}
	var s ProfileSummary
	if err := json.Unmarshal(res.Head, &s); err != nil {
		return s, nil, err
	}
	if s.Err != "" {
		return s, nil, errors.New(s.Err)
	}
	return s, res.Raw, nil
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
	// the last action of the phone done (main/account.lua drops it from its queue)
	Last int64 `json:"ultima"`
	// the phone's matches not paid in this request (the receipt says «non valida»)
	Refused []int64 `json:"rifiutate,omitempty"`
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

// a profile blocked from the panel (recovery.go): no actions, no prizes
var errBlocked = errors.New("profilo bloccato")

// the day of the rules (the first win, the bots' matches, the BOTTEGA) is
// Italy's (rome, events.go), never the phone's clock
func today(now time.Time) string { return now.In(rome).Format("2006-01-02") }

// Do does the phone's actions (actions: sim/replay.lua text, { azioni = {
// { n, k, ... } } }; empty: none) on the profile of id if key is its key, and
// returns it. The actions up to the last one already done are skipped (the
// phone sends again what got no answer).
func (a *Accounts) Do(id int64, key, actions string, now time.Time) (Account, ProfileSummary, error) {
	a.mu.Lock()
	defer a.mu.Unlock()
	var acc Account
	var hash string
	var owner int
	var phoneCopy sql.NullString
	var blocked int
	err := a.db.QueryRow(`SELECT id, chiave, nome, rev, profilo, padrone, ultima, copia, bloccato FROM giocatori WHERE id = ?`, id).
		Scan(&acc.ID, &hash, &acc.Name, &acc.Rev, &acc.Profile, &owner, &acc.Last, &phoneCopy, &blocked)
	if errors.Is(err, sql.ErrNoRows) || err == nil && subtle.ConstantTimeCompare([]byte(hash), []byte(hashKey(key))) != 1 {
		return Account{}, ProfileSummary{}, errNoProfile
	}
	if err == nil && blocked != 0 {
		return Account{}, ProfileSummary{}, errBlocked
	}
	if err != nil {
		return Account{}, ProfileSummary{}, err
	}
	var kinds []string
	var took ProfileSummary
	if owner == 0 && phoneCopy.Valid && phoneCopy.String != "" {
		// the first request of PR 4: the phone's latest copy (it counted until
		// now) becomes the server's, through the import like at the birth
		if took, err = profileLua("profile_new", map[string]string{"name": acc.Name, "text": phoneCopy.String}); err == nil {
			acc.Profile = took.Profile
			kinds = append(kinds, "padrone")
		}
	}
	s, err := profileLua("profile_do", map[string]string{"text": acc.Profile, "actions": actions,
		"today": today(now), "last": strconv.FormatInt(acc.Last, 10)})
	if err != nil {
		return Account{}, s, err
	}
	acc.Refused = s.Refused
	if s.Done == "" && len(kinds) == 0 && owner == 1 {
		return acc, s, nil
	}
	acc.Profile, acc.Last, acc.Rev = s.Profile, s.Last, acc.Rev+1
	tx, err := a.db.Begin()
	if err != nil {
		return Account{}, s, err
	}
	defer tx.Rollback()
	if _, err := tx.Exec(`UPDATE giocatori SET profilo = ?, rev = ?, ultima = ?, padrone = 1, aggiornato = ? WHERE id = ?`,
		acc.Profile, acc.Rev, acc.Last, now.Unix(), id); err != nil {
		return Account{}, s, err
	}
	if len(kinds) > 0 {
		if err := ledger(tx, id, now.Unix(), "padrone", took); err != nil {
			return Account{}, s, err
		}
	}
	if s.Done != "" {
		if err := ledger(tx, id, now.Unix(), "azioni", s); err != nil {
			return Account{}, s, err
		}
	}
	return acc, s, tx.Commit()
}

// Cards: what the player of id (with key) shows and wears online, from the
// server's profile (sim/profile.lua showcase and equip, as JSON): the phone's
// word doesn't count (server.go, hello)
func (a *Accounts) Cards(id int64, key string) (showcase, equip json.RawMessage, err error) {
	acc, _, err := a.Do(id, key, "", time.Now())
	if err != nil {
		return nil, nil, err
	}
	b := &Batch{}
	b.Cmd("profile_cards", 0, nil)
	b.Str("text", acc.Profile)
	b.End()
	res, err := callUtil(b)
	if err != nil {
		return nil, nil, err
	}
	var v struct {
		Showcase json.RawMessage `json:"vetrina"`
		Equip    json.RawMessage `json:"eq"`
		Err      string          `json:"err"`
	}
	if err := json.Unmarshal(res.Head, &v); err != nil {
		return nil, nil, err
	}
	if v.Err != "" {
		return nil, nil, errors.New(v.Err)
	}
	return v.Showcase, v.Equip, nil
}

// Award gives the profile of id an online match (action: worker.lua prizes,
// made by the server). Returns the gain as JSON, for the phone's podium.
func (a *Accounts) Award(id int64, action string, now time.Time) ([]byte, ProfileSummary, error) {
	a.mu.Lock()
	defer a.mu.Unlock()
	var text string
	var rev int64
	if err := a.db.QueryRow(`SELECT profilo, rev FROM giocatori WHERE id = ? AND bloccato = 0`, id).Scan(&text, &rev); err != nil {
		return nil, ProfileSummary{}, err
	}
	s, raws, err := profileCall("profile_award", map[string]string{"text": text, "action": action, "today": today(now)})
	if err != nil {
		return nil, s, err
	}
	tx, err := a.db.Begin()
	if err != nil {
		return nil, s, err
	}
	defer tx.Rollback()
	if _, err := tx.Exec(`UPDATE giocatori SET profilo = ?, rev = ?, padrone = 1, aggiornato = ? WHERE id = ?`,
		s.Profile, rev+1, now.Unix(), id); err != nil {
		return nil, s, err
	}
	if err := ledger(tx, id, now.Unix(), "online", s); err != nil {
		return nil, s, err
	}
	var gain []byte
	if len(raws) > 0 {
		gain = raws[0]
	}
	return gain, s, tx.Commit()
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
	return a.allow(a.births, ip, now, profileNewPerHour)
}

// allow: whether ip can do one more of what m counts, at most max in an hour
func (a *Accounts) allow(m map[string][]time.Time, ip string, now time.Time, max int) bool {
	a.nmu.Lock()
	defer a.nmu.Unlock()
	kept := m[ip][:0]
	for _, t := range m[ip] {
		if now.Sub(t) < time.Hour {
			kept = append(kept, t)
		}
	}
	if len(kept) >= max {
		m[ip] = kept
		return false
	}
	m[ip] = append(kept, now)
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

// /profilo/nuovo, /profilo/fai, /profilo/codice, /profilo/recupera (docs/server.md, "Profili ospite")
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
	case "/profilo/fai":
		id, key, ok := authProfile(r)
		if !ok {
			http.Error(w, errNoProfile.Error(), http.StatusUnauthorized)
			return
		}
		acc, sum, err := a.Do(id, key, string(body), time.Now())
		if errors.Is(err, errNoProfile) {
			http.Error(w, err.Error(), http.StatusUnauthorized)
			return
		}
		if errors.Is(err, errBlocked) {
			http.Error(w, err.Error(), http.StatusForbidden)
			return
		}
		if err != nil {
			log.Printf("profili: azioni di %d da %s rifiutate: %v", id, who, err)
			http.Error(w, "azioni rifiutate", http.StatusBadRequest)
			return
		}
		if sum.Done != "" {
			log.Printf("profili: %d da %s ha fatto %s: %s", id, who, sum.Done, sum)
		}
		writeJSON(w, acc)
	case "/profilo/codice", "/profilo/recupera":
		s.handleRecovery(w, r, a, body, who)
	default:
		http.NotFound(w, r)
	}
}
