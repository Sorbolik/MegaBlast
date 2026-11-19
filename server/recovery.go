package main

// Finding a profile again (step 6 of the guest profiles plan, docs/server.md
// "Ritrovare il profilo"): the recovery code that the phone shows in the
// IMPOSTAZIONI, the way back on a new phone with it, and the panel's commands
// (search, ledger, block, import again) that Sergio runs from GitHub Actions
// (.github/workflows/profili.yml: megablast-server -profili FILE profili ...).

import (
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"
)

const (
	// the code's letters: no 0/O, 1/I/L, to copy it by hand without mistakes
	codeAlphabet = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
	codeLen      = 12
	// codes tried from one address in an hour (one is enough to come back)
	codeTriesPerHour = 10
)

var errNoCode = errors.New("codice sconosciuto")

// newCode: 12 letters of codeAlphabet, shown in groups of four (ABCD-EFGH-JKMN)
func newCode() (string, error) {
	raw := make([]byte, codeLen)
	if _, err := rand.Read(raw); err != nil {
		return "", err
	}
	var b strings.Builder
	for i, c := range raw {
		if i > 0 && i%4 == 0 {
			b.WriteByte('-')
		}
		b.WriteByte(codeAlphabet[int(c)%len(codeAlphabet)])
	}
	return b.String(), nil
}

// cleanCode: what the player typed, as the code is kept (capitals, no dashes
// or spaces); "" if it can't be a code
func cleanCode(s string) string {
	var b strings.Builder
	for _, c := range strings.ToUpper(s) {
		switch {
		case c == '-' || c == ' ':
		case strings.ContainsRune(codeAlphabet, c):
			b.WriteRune(c)
		default:
			return ""
		}
	}
	if b.Len() != codeLen {
		return ""
	}
	return b.String()
}

// Code gives the profile of id (with key) a new recovery code: the old one
// stops working. The server keeps only its fingerprint.
func (a *Accounts) Code(id int64, key string, now time.Time) (string, error) {
	if _, _, err := a.Do(id, key, "", now); err != nil {
		return "", err
	}
	code, err := newCode()
	if err != nil {
		return "", err
	}
	a.mu.Lock()
	defer a.mu.Unlock()
	tx, err := a.db.Begin()
	if err != nil {
		return "", err
	}
	defer tx.Rollback()
	if _, err := tx.Exec(`UPDATE giocatori SET codice = ? WHERE id = ?`, hashKey(cleanCode(code)), id); err != nil {
		return "", err
	}
	if err := ledger(tx, id, now.Unix(), "codice", ProfileSummary{}); err != nil {
		return "", err
	}
	return code, tx.Commit()
}

// Recover: the profile whose recovery code is code, with a new key (the old
// phone's stops working, it gets a profile of its own)
func (a *Accounts) Recover(code string, now time.Time) (Account, error) {
	c := cleanCode(code)
	if c == "" {
		return Account{}, errNoCode
	}
	raw := make([]byte, 24)
	if _, err := rand.Read(raw); err != nil {
		return Account{}, err
	}
	key := hex.EncodeToString(raw)
	a.mu.Lock()
	defer a.mu.Unlock()
	var acc Account
	err := a.db.QueryRow(`SELECT id, nome, rev, profilo, ultima FROM giocatori WHERE codice = ? AND bloccato = 0`, hashKey(c)).
		Scan(&acc.ID, &acc.Name, &acc.Rev, &acc.Profile, &acc.Last)
	if errors.Is(err, sql.ErrNoRows) {
		return Account{}, errNoCode
	}
	if err != nil {
		return Account{}, err
	}
	tx, err := a.db.Begin()
	if err != nil {
		return Account{}, err
	}
	defer tx.Rollback()
	acc.Rev++
	if _, err := tx.Exec(`UPDATE giocatori SET chiave = ?, rev = ?, aggiornato = ? WHERE id = ?`, hashKey(key), acc.Rev, now.Unix(), acc.ID); err != nil {
		return Account{}, err
	}
	if err := ledger(tx, acc.ID, now.Unix(), "recupero", ProfileSummary{}); err != nil {
		return Account{}, err
	}
	acc.Key = key
	return acc, tx.Commit()
}

// /profilo/codice (with the key: a new code) and /profilo/recupera (the body
// is the code: the profile with a new key)
func (s *Server) handleRecovery(w http.ResponseWriter, r *http.Request, a *Accounts, body []byte, who string) {
	now := time.Now()
	if r.URL.Path == "/profilo/codice" {
		id, key, ok := authProfile(r)
		if !ok {
			http.Error(w, errNoProfile.Error(), http.StatusUnauthorized)
			return
		}
		code, err := a.Code(id, key, now)
		switch {
		case errors.Is(err, errNoProfile):
			http.Error(w, err.Error(), http.StatusUnauthorized)
		case errors.Is(err, errBlocked):
			http.Error(w, err.Error(), http.StatusForbidden)
		case err != nil:
			log.Printf("profili: codice di %d da %s non fatto: %v", id, who, err)
			http.Error(w, "codice non fatto", http.StatusInternalServerError)
		default:
			log.Printf("profili: %d da %s ha un codice nuovo", id, who)
			writeJSON(w, map[string]string{"codice": code})
		}
		return
	}
	ip := requestIP(r)
	if !a.allow(a.tries, ip, now, codeTriesPerHour) {
		log.Printf("profili: recupero da %s (%s) rifiutato, troppi tentativi in un'ora", who, ip)
		http.Error(w, "troppi tentativi", http.StatusTooManyRequests)
		return
	}
	acc, err := a.Recover(string(body), now)
	if errors.Is(err, errNoCode) {
		log.Printf("profili: recupero da %s con un codice sconosciuto", who)
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}
	if err != nil {
		log.Printf("profili: recupero da %s non fatto: %v", who, err)
		http.Error(w, "recupero non fatto", http.StatusInternalServerError)
		return
	}
	log.Printf("profili: %d recuperato da %s", acc.ID, who)
	writeJSON(w, acc)
}

// The panel (profili.yml): megablast-server -profili FILE profili COMANDO [ARG]
//
//	cerca TESTO     profiles by number or by a piece of the name
//	registro N      the last 40 movements of profile N
//	blocca N        no more actions or prizes for N (sblocca N: back)
//	reimporta N     N's profile again from the phone's last copy (PR 3), cut to the caps
func profileAdmin(acc *Accounts, args []string, out io.Writer) error {
	if len(args) < 2 {
		return errors.New("uso: profili cerca|registro|blocca|sblocca|reimporta ARGOMENTO")
	}
	cmd, arg := args[0], strings.TrimSpace(strings.Join(args[1:], " "))
	if cmd == "cerca" {
		return acc.search(arg, out)
	}
	id, err := strconv.ParseInt(arg, 10, 64)
	if err != nil || id <= 0 {
		return fmt.Errorf("numero del profilo sbagliato: %q", arg)
	}
	now := time.Now().Unix()
	switch cmd {
	case "registro":
		return acc.history(id, out)
	case "blocca", "sblocca":
		v := 0
		if cmd == "blocca" {
			v = 1
		}
		return acc.write(id, now, cmd, out, func(tx *sql.Tx) error {
			_, err := tx.Exec(`UPDATE giocatori SET bloccato = ? WHERE id = ?`, v, id)
			return err
		})
	case "reimporta":
		var name string
		var copy sql.NullString
		if err := acc.db.QueryRow(`SELECT nome, copia FROM giocatori WHERE id = ?`, id).Scan(&name, &copy); err != nil {
			return err
		}
		if !copy.Valid || copy.String == "" {
			return errors.New("di questo profilo il server non ha la copia del telefono")
		}
		s, err := profileLua("profile_new", map[string]string{"name": name, "text": copy.String})
		if err != nil {
			return err
		}
		fmt.Fprintf(out, "reimportato: %s\n", s)
		return acc.write(id, now, "reimporta", out, func(tx *sql.Tx) error {
			_, err := tx.Exec(`UPDATE giocatori SET profilo = ?, rev = rev + 1, padrone = 1, aggiornato = ? WHERE id = ?`, s.Profile, now, id)
			if err == nil {
				err = ledger(tx, id, now, "reimporta", s)
			}
			return err
		})
	}
	return fmt.Errorf("comando sconosciuto: %s", cmd)
}

// write: change in a transaction one profile that exists, with a ledger row
func (a *Accounts) write(id, now int64, kind string, out io.Writer, f func(*sql.Tx) error) error {
	a.mu.Lock()
	defer a.mu.Unlock()
	tx, err := a.db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	var n int
	if err := tx.QueryRow(`SELECT COUNT(*) FROM giocatori WHERE id = ?`, id).Scan(&n); err != nil || n == 0 {
		return fmt.Errorf("profilo %d sconosciuto", id)
	}
	if err := f(tx); err != nil {
		return err
	}
	if kind != "reimporta" {
		if err := ledger(tx, id, now, kind, ProfileSummary{}); err != nil {
			return err
		}
	}
	if err := tx.Commit(); err != nil {
		return err
	}
	fmt.Fprintf(out, "profilo %d: %s fatto\n", id, kind)
	return nil
}

func (a *Accounts) search(text string, out io.Writer) error {
	id, _ := strconv.ParseInt(text, 10, 64)
	rows, err := a.db.Query(`SELECT id, nome, profilo, creato, aggiornato, bloccato, codice IS NOT NULL FROM giocatori
		WHERE id = ? OR nome LIKE ? ORDER BY id LIMIT 50`, id, "%"+text+"%")
	if err != nil {
		return err
	}
	defer rows.Close()
	type row struct {
		id                int64
		name, text        string
		born, seen        int64
		blocked, withCode bool
	}
	var list []row
	for rows.Next() {
		var r row
		if err := rows.Scan(&r.id, &r.name, &r.text, &r.born, &r.seen, &r.blocked, &r.withCode); err != nil {
			return err
		}
		list = append(list, r)
	}
	if err := rows.Err(); err != nil {
		return err
	}
	rows.Close()
	if len(list) == 0 {
		fmt.Fprintln(out, "nessun profilo")
	}
	for _, r := range list {
		sum, err := profileLua("profile_summary", map[string]string{"text": r.text})
		what := sum.String()
		if err != nil {
			what = "profilo illeggibile: " + err.Error()
		}
		flags := ""
		if r.blocked {
			flags += " BLOCCATO"
		}
		if r.withCode {
			flags += " (ha il codice)"
		}
		fmt.Fprintf(out, "%d  %s  %s  nato %s, visto %s%s\n", r.id, r.name, what,
			time.Unix(r.born, 0).In(rome).Format("2006-01-02 15:04"), time.Unix(r.seen, 0).In(rome).Format("2006-01-02 15:04"), flags)
	}
	return nil
}

func (a *Accounts) history(id int64, out io.Writer) error {
	rows, err := a.db.Query(`SELECT quando, tipo, dati FROM registro WHERE giocatore = ? ORDER BY id DESC LIMIT 40`, id)
	if err != nil {
		return err
	}
	defer rows.Close()
	n := 0
	for rows.Next() {
		var when int64
		var kind, data string
		if err := rows.Scan(&when, &kind, &data); err != nil {
			return err
		}
		fmt.Fprintf(out, "%s  %-10s %s\n", time.Unix(when, 0).In(rome).Format("2006-01-02 15:04"), kind, data)
		n++
	}
	if n == 0 {
		fmt.Fprintln(out, "niente nel registro")
	}
	return rows.Err()
}
