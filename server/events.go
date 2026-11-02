package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"regexp"
	"sort"
	"strings"
	"sync"
	"time"
	_ "time/tzdata" // gli orari degli eventi sono di Roma anche su un server senza fusi orari

	lua "github.com/yuin/gopher-lua"
)

// Il calendario degli eventi (docs/server.md, "Eventi"): Sergio lo fa nel
// pannello degli eventi (strumenti/eventi, un Worker di Cloudflare) e il server
// lo scarica ogni 30 secondi (go run ./server -eventi https://…/eventi.json),
// oppure lo legge da un file JSON (-eventi eventi.json) che rilegge da solo
// quando cambia. Un evento è un modello con la sua
// finestra e, se vuole, una ripetizione: ogni N settimane fino a una data o per
// sempre. Il server lo espande nelle occorrenze dei prossimi giorni, ognuna
// col suo id (evento-AAAAMMGG), e le dà al gioco con GET /eventi.
//
// Un evento o si appoggia a una coda normale (Torneo, Sfida, XP: conta per le
// partite di quella coda) o ha una coda sua (modificatore: "modo" dice le
// squadre, "regole" cosa cambia, sim/rules.lua). Il giocatore sceglie solo la
// coda: una partita conta per tutti gli eventi attaccati alla sua coda.
//
//	{"eventi": [{
//	  "id": "maglio", "tipo": "mod", "nome": "2V2 SOLO MAGLIO",
//	  "riga": "Una sola arma, colpi che fanno volare.",
//	  "da": "2026-11-02 10:00", "a": "2026-11-04 23:59", "ogni": 2, "fino": "2027-01-31",
//	  "modo": "2v2", "regole": {"armi": ["punch", "mallet"]},  (su una coda normale solo {"tetto": 15})
//	  "premi": [{"testo": "Badge Maglio", "fino": 100}]
//	}]}
//
// "premi" e "obiettivo" il server li passa così come sono: li legge il gioco.

// Quanti giorni avanti il server espande le ripetizioni (le due strisce della bacheca).
const daysAhead = 14

var rome = func() *time.Location {
	l, err := time.LoadLocation("Europe/Rome")
	if err != nil {
		panic(err)
	}
	return l
}()

// Tipi di evento: quelli con la coda sua e quelli che stanno su una coda normale.
var eventKinds = map[string]bool{"mod": true, "torneo": false, "sfida": false, "xp": false}

var eventID = regexp.MustCompile(`^[a-z0-9_]{1,32}$`)

// Evento è come Sergio lo scrive nel file.
type Event struct {
	ID        string          `json:"id"`
	Kind      string          `json:"tipo"`
	Title      string          `json:"nome"`
	Line      string          `json:"riga"`
	From        string          `json:"da"`   // "2026-11-02 10:00", ora di Roma
	A         string          `json:"a"`    // fine della prima finestra
	Every      int             `json:"ogni"` // settimane fra una volta e l'altra, 0 = una volta sola
	Until      string          `json:"fino"` // "2027-01-31": l'ultimo giorno in cui può ricominciare; vuoto = per sempre
	Teams      string          `json:"modo"` // coda sua: le squadre (1v1, 2v2, ffa)
	Queue      string          `json:"coda"` // coda normale a cui si appoggia (di solito 2v2)
	Rules    json.RawMessage `json:"regole"`
	Rewards     json.RawMessage `json:"premi"`
	Goal json.RawMessage `json:"obiettivo"`

	da, a, until time.Time
}

// Occorrenza è una volta di un evento, come la vede il gioco.
type Occurrence struct {
	ID        string          `json:"id"`
	Event    string          `json:"evento"`
	Kind      string          `json:"tipo"`
	Title      string          `json:"nome"`
	Line      string          `json:"riga,omitempty"`
	From        int64           `json:"da"`              // secondi Unix
	A         int64           `json:"a"`               // secondi Unix
	Next     int64           `json:"torna,omitempty"` // la volta dopo, se c'è
	Queue      string          `json:"coda"`            // la coda da chiedere nel hello per giocarlo
	Teams      string          `json:"modo"`            // le squadre della partita
	PlayerCount int             `json:"giocatori"`
	Rules    json.RawMessage `json:"regole,omitempty"`
	Rewards     json.RawMessage `json:"premi,omitempty"`
	Goal json.RawMessage `json:"obiettivo,omitempty"`
}

// Ogni quanto il server chiede il calendario al pannello.
const panelPoll = 30 * time.Second

// Calendario legge il file degli eventi e lo rilegge quando cambia, o lo
// scarica dal pannello.
type Calendar struct {
	path string
	now  func() time.Time

	mu       sync.Mutex
	events   []Event
	modTime  time.Time
	checkedAt time.Time

	// dal pannello: la versione presa (ETag), l'errore se il server l'ha
	// rifiutata (il pannello lo mostra a Sergio) e l'ultimo problema di rete
	version, rejected, rete string
}

func NewCalendar(path string) *Calendar {
	c := &Calendar{path: path, now: time.Now}
	if fromPanel(path) {
		client := &http.Client{Timeout: 10 * time.Second}
		c.download(client)
		go func() {
			for range time.Tick(panelPoll) {
				c.download(client)
			}
		}()
		return c
	}
	c.reload()
	return c
}

func fromPanel(path string) bool {
	return strings.HasPrefix(path, "https://") || strings.HasPrefix(path, "http://")
}

// scarica chiede il calendario al pannello. Nella domanda dice quale versione
// ha preso e, se l'ha rifiutata, perché: il pannello lo mostra a Sergio. Come
// per il file, un calendario sbagliato non sostituisce quello buono, e se il
// pannello non risponde resta quello di prima.
func (c *Calendar) download(client *http.Client) {
	c.mu.Lock()
	u, etag := c.path, c.version
	if c.version != "" {
		u += "?" + url.Values{"preso": {strings.Trim(c.version, `"`)}, "errore": {c.rejected}}.Encode()
	}
	c.mu.Unlock()
	req, err := http.NewRequest("GET", u, nil)
	if err != nil {
		c.problem(err.Error())
		return
	}
	if etag != "" {
		req.Header.Set("If-None-Match", etag)
	}
	res, err := client.Do(req)
	if err != nil {
		c.problem(err.Error())
		return
	}
	defer res.Body.Close()
	if res.StatusCode == http.StatusNotModified {
		c.problem("")
		return
	}
	data, err := io.ReadAll(io.LimitReader(res.Body, 4<<20))
	if err == nil && res.StatusCode != http.StatusOK {
		err = fmt.Errorf("%s", res.Status)
	}
	if err != nil {
		c.problem(err.Error())
		return
	}
	c.problem("")
	ev, err := readEvents(data)
	c.mu.Lock()
	defer c.mu.Unlock()
	c.version = res.Header.Get("ETag")
	if err != nil {
		c.rejected = err.Error()
		log.Printf("eventi: la versione %s del pannello non va, tengo il calendario di prima: %v", c.version, err)
		return
	}
	c.events, c.rejected = ev, ""
	log.Printf("eventi: %d dal pannello (versione %s)", len(ev), c.version)
}

// problema scrive nel log un problema di rete col pannello solo quando cambia
func (c *Calendar) problem(p string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if p != c.rete && p != "" {
		log.Printf("eventi: il pannello non risponde, tengo il calendario di prima: %s", p)
	} else if p == "" && c.rete != "" {
		log.Printf("eventi: il pannello risponde di nuovo")
	}
	c.rete = p
}

// aggiorna rilegge il file se è cambiato (al massimo ogni due secondi). Un
// file sbagliato non cancella il calendario buono: resta quello di prima e
// l'errore va nel log.
func (c *Calendar) reload() {
	if c.path == "" || fromPanel(c.path) {
		return
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	now := c.now()
	if !c.checkedAt.IsZero() && now.Sub(c.checkedAt) < 2*time.Second {
		return
	}
	c.checkedAt = now
	st, err := os.Stat(c.path)
	if err != nil {
		if !c.modTime.IsZero() || c.events == nil {
			log.Printf("eventi: %v", err)
		}
		c.events, c.modTime = []Event{}, time.Time{}
		return
	}
	if st.ModTime().Equal(c.modTime) {
		return
	}
	c.modTime = st.ModTime()
	data, err := os.ReadFile(c.path)
	if err == nil {
		var ev []Event
		if ev, err = readEvents(data); err == nil {
			c.events = ev
			log.Printf("eventi: %d letti da %s", len(ev), c.path)
			return
		}
	}
	log.Printf("eventi: %s non va, tengo il calendario di prima: %v", c.path, err)
}

// leggiEventi controlla tutto il file: un errore e non si usa niente.
func readEvents(data []byte) ([]Event, error) {
	var f struct {
		EventList []Event `json:"eventi"`
	}
	dec := json.NewDecoder(bytes.NewReader(data))
	dec.DisallowUnknownFields() // un campo scritto male si vede subito
	if err := dec.Decode(&f); err != nil {
		return nil, err
	}
	seen := map[string]bool{}
	var eng *Engine
	defer func() {
		if eng != nil {
			eng.L.Close()
		}
	}()
	for i := range f.EventList {
		e := &f.EventList[i]
		if err := e.check(); err != nil {
			return nil, fmt.Errorf("evento %q: %w", e.ID, err)
		}
		if seen[e.ID] {
			return nil, fmt.Errorf("evento %q: id ripetuto", e.ID)
		}
		seen[e.ID] = true
		if len(e.Rules) > 0 {
			if eng == nil {
				var err error
				if eng, err = newEngine(); err != nil {
					return nil, err
				}
			}
			r, err := eng.fromJSON(e.Rules)
			if err == nil {
				var v interface{ String() string }
				if v, err = eng.call("regole_valida", r, lua.LBool(e.Teams == "")); err == nil && v.String() != "" {
					err = fmt.Errorf("regole: %s", v.String())
				}
			}
			if err != nil {
				return nil, fmt.Errorf("evento %q: %w", e.ID, err)
			}
		}
	}
	return f.EventList, nil
}

func (e *Event) check() error {
	var err error
	if !eventID.MatchString(e.ID) {
		return fmt.Errorf("id: lettere minuscole, cifre e _")
	}
	if _, ok := modes[e.ID]; ok {
		return fmt.Errorf("id: %q è già una coda normale", e.ID)
	}
	own, ok := eventKinds[e.Kind]
	if !ok {
		return fmt.Errorf("tipo: mod, torneo, sfida o xp")
	}
	if e.Title == "" {
		return fmt.Errorf("manca il nome")
	}
	if e.da, err = time.ParseInLocation("2006-01-02 15:04", e.From, rome); err != nil {
		return fmt.Errorf("da: %w", err)
	}
	if e.a, err = time.ParseInLocation("2006-01-02 15:04", e.A, rome); err != nil {
		return fmt.Errorf("a: %w", err)
	}
	if !e.a.After(e.da) {
		return fmt.Errorf("a viene prima di da")
	}
	if e.Every < 0 {
		return fmt.Errorf("ogni: settimane, 0 = una volta sola")
	}
	if e.Every > 0 && e.a.Sub(e.da) > time.Duration(e.Every)*7*24*time.Hour {
		return fmt.Errorf("dura più di %d settimane: si accavallerebbe con la volta dopo", e.Every)
	}
	if e.Until != "" {
		if e.until, err = time.ParseInLocation("2006-01-02", e.Until, rome); err != nil {
			return fmt.Errorf("fino: %w", err)
		}
		e.until = e.until.AddDate(0, 0, 1) // compreso quel giorno
	}
	if own {
		if _, ok := modes[e.Teams]; !ok {
			return fmt.Errorf("modo: 1v1, 2v2 o ffa")
		}
		if e.Queue != "" {
			return fmt.Errorf("coda: un evento con la coda sua non sta su un'altra")
		}
	} else {
		if e.Queue == "" {
			e.Queue = "2v2"
		}
		if _, ok := modes[e.Queue]; !ok {
			return fmt.Errorf("coda: 1v1, 2v2 o ffa")
		}
		if e.Teams != "" {
			return fmt.Errorf("modo solo per i modificatori (tipo mod), che hanno la coda loro")
		}
		// le regole che cambiano la partita su una coda normale la cambierebbero a
		// tutti: lì passa solo il tetto ai livelli (regole.CODA_NORMALE, leggiEventi)
	}
	return nil
}

// volta k dell'evento: inizio e fine (AddDate tiene l'ora anche col cambio dell'ora legale)
func (e *Event) window(k int) (time.Time, time.Time, bool) {
	if k > 0 && e.Every == 0 {
		return time.Time{}, time.Time{}, false
	}
	da, a := e.da.AddDate(0, 0, 7*e.Every*k), e.a.AddDate(0, 0, 7*e.Every*k)
	if !e.until.IsZero() && !da.Before(e.until) {
		return da, a, false
	}
	return da, a, true
}

func (e *Event) occurrence(da, a time.Time) Occurrence {
	o := Occurrence{
		ID: e.ID + "-" + da.In(rome).Format("20060102"), Event: e.ID, Kind: e.Kind,
		Title: e.Title, Line: e.Line, From: da.Unix(), A: a.Unix(),
		Rules: e.Rules, Rewards: e.Rewards, Goal: e.Goal,
	}
	if e.Teams != "" {
		o.Queue, o.Teams = o.ID, e.Teams
	} else {
		o.Queue, o.Teams = e.Queue, e.Queue
	}
	o.PlayerCount = modes[o.Teams].Players
	return o
}

// Occorrenze: quelle in corso adesso e quelle che cominciano nei prossimi
// giorniAvanti giorni, in ordine di inizio.
func (c *Calendar) Occurrences() []Occurrence {
	c.reload()
	c.mu.Lock()
	events, now := c.events, c.now()
	c.mu.Unlock()
	limit := now.AddDate(0, 0, daysAhead)
	out := []Occurrence{}
	for i := range events {
		e := &events[i]
		// salta le volte già finite senza contarle una a una
		k := 0
		if e.Every > 0 && now.After(e.a) {
			k = int(now.Sub(e.a)/(time.Duration(e.Every)*7*24*time.Hour)) - 1
			k = max(k, 0)
		}
		for ; ; k++ {
			da, a, ok := e.window(k)
			if !ok || da.After(limit) {
				break
			}
			if !a.After(now) {
				continue
			}
			o := e.occurrence(da, a)
			if after, _, ok := e.window(k + 1); ok {
				o.Next = after.Unix()
			}
			out = append(out, o)
		}
	}
	sort.SliceStable(out, func(i, j int) bool {
		if out[i].From != out[j].From {
			return out[i].From < out[j].From
		}
		return out[i].ID < out[j].ID
	})
	return out
}

// Coda trova la coda di un evento in corso dal suo id (evento-AAAAMMGG).
func (c *Calendar) Queue(id string) (Mode, bool) {
	now := c.now().Unix()
	for _, o := range c.Occurrences() {
		if o.Queue == id && o.Teams != o.Queue && o.From <= now && now < o.A {
			return Mode{Name: o.ID, Players: o.PlayerCount, Sim: o.Teams, Rules: o.Rules}, true
		}
	}
	return Mode{}, false
}
