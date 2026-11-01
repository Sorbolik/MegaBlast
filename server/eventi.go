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
// squadre, "regole" cosa cambia, sim/regole.lua). Il giocatore sceglie solo la
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
const giorniAvanti = 14

var roma = func() *time.Location {
	l, err := time.LoadLocation("Europe/Rome")
	if err != nil {
		panic(err)
	}
	return l
}()

// Tipi di evento: quelli con la coda sua e quelli che stanno su una coda normale.
var tipiEvento = map[string]bool{"mod": true, "torneo": false, "sfida": false, "xp": false}

var idEvento = regexp.MustCompile(`^[a-z0-9_]{1,32}$`)

// Evento è come Sergio lo scrive nel file.
type Evento struct {
	ID        string          `json:"id"`
	Tipo      string          `json:"tipo"`
	Nome      string          `json:"nome"`
	Riga      string          `json:"riga"`
	Da        string          `json:"da"`   // "2026-11-02 10:00", ora di Roma
	A         string          `json:"a"`    // fine della prima finestra
	Ogni      int             `json:"ogni"` // settimane fra una volta e l'altra, 0 = una volta sola
	Fino      string          `json:"fino"` // "2027-01-31": l'ultimo giorno in cui può ricominciare; vuoto = per sempre
	Modo      string          `json:"modo"` // coda sua: le squadre (1v1, 2v2, ffa)
	Coda      string          `json:"coda"` // coda normale a cui si appoggia (di solito 2v2)
	Regole    json.RawMessage `json:"regole"`
	Premi     json.RawMessage `json:"premi"`
	Obiettivo json.RawMessage `json:"obiettivo"`

	da, a, fino time.Time
}

// Occorrenza è una volta di un evento, come la vede il gioco.
type Occorrenza struct {
	ID        string          `json:"id"`
	Evento    string          `json:"evento"`
	Tipo      string          `json:"tipo"`
	Nome      string          `json:"nome"`
	Riga      string          `json:"riga,omitempty"`
	Da        int64           `json:"da"`              // secondi Unix
	A         int64           `json:"a"`               // secondi Unix
	Torna     int64           `json:"torna,omitempty"` // la volta dopo, se c'è
	Coda      string          `json:"coda"`            // la coda da chiedere nel hello per giocarlo
	Modo      string          `json:"modo"`            // le squadre della partita
	Giocatori int             `json:"giocatori"`
	Regole    json.RawMessage `json:"regole,omitempty"`
	Premi     json.RawMessage `json:"premi,omitempty"`
	Obiettivo json.RawMessage `json:"obiettivo,omitempty"`
}

// Ogni quanto il server chiede il calendario al pannello.
const ogniQuantoPannello = 30 * time.Second

// Calendario legge il file degli eventi e lo rilegge quando cambia, o lo
// scarica dal pannello.
type Calendario struct {
	path string
	now  func() time.Time

	mu       sync.Mutex
	eventi   []Evento
	modTime  time.Time
	guardato time.Time

	// dal pannello: la versione presa (ETag), l'errore se il server l'ha
	// rifiutata (il pannello lo mostra a Sergio) e l'ultimo problema di rete
	versione, errore, rete string
}

func NewCalendario(path string) *Calendario {
	c := &Calendario{path: path, now: time.Now}
	if dalPannello(path) {
		client := &http.Client{Timeout: 10 * time.Second}
		c.scarica(client)
		go func() {
			for range time.Tick(ogniQuantoPannello) {
				c.scarica(client)
			}
		}()
		return c
	}
	c.aggiorna()
	return c
}

func dalPannello(path string) bool {
	return strings.HasPrefix(path, "https://") || strings.HasPrefix(path, "http://")
}

// scarica chiede il calendario al pannello. Nella domanda dice quale versione
// ha preso e, se l'ha rifiutata, perché: il pannello lo mostra a Sergio. Come
// per il file, un calendario sbagliato non sostituisce quello buono, e se il
// pannello non risponde resta quello di prima.
func (c *Calendario) scarica(client *http.Client) {
	c.mu.Lock()
	u, etag := c.path, c.versione
	if c.versione != "" {
		u += "?" + url.Values{"preso": {strings.Trim(c.versione, `"`)}, "errore": {c.errore}}.Encode()
	}
	c.mu.Unlock()
	req, err := http.NewRequest("GET", u, nil)
	if err != nil {
		c.problema(err.Error())
		return
	}
	if etag != "" {
		req.Header.Set("If-None-Match", etag)
	}
	res, err := client.Do(req)
	if err != nil {
		c.problema(err.Error())
		return
	}
	defer res.Body.Close()
	if res.StatusCode == http.StatusNotModified {
		c.problema("")
		return
	}
	data, err := io.ReadAll(io.LimitReader(res.Body, 4<<20))
	if err == nil && res.StatusCode != http.StatusOK {
		err = fmt.Errorf("%s", res.Status)
	}
	if err != nil {
		c.problema(err.Error())
		return
	}
	c.problema("")
	ev, err := leggiEventi(data)
	c.mu.Lock()
	defer c.mu.Unlock()
	c.versione = res.Header.Get("ETag")
	if err != nil {
		c.errore = err.Error()
		log.Printf("eventi: la versione %s del pannello non va, tengo il calendario di prima: %v", c.versione, err)
		return
	}
	c.eventi, c.errore = ev, ""
	log.Printf("eventi: %d dal pannello (versione %s)", len(ev), c.versione)
}

// problema scrive nel log un problema di rete col pannello solo quando cambia
func (c *Calendario) problema(p string) {
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
func (c *Calendario) aggiorna() {
	if c.path == "" || dalPannello(c.path) {
		return
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	now := c.now()
	if !c.guardato.IsZero() && now.Sub(c.guardato) < 2*time.Second {
		return
	}
	c.guardato = now
	st, err := os.Stat(c.path)
	if err != nil {
		if !c.modTime.IsZero() || c.eventi == nil {
			log.Printf("eventi: %v", err)
		}
		c.eventi, c.modTime = []Evento{}, time.Time{}
		return
	}
	if st.ModTime().Equal(c.modTime) {
		return
	}
	c.modTime = st.ModTime()
	data, err := os.ReadFile(c.path)
	if err == nil {
		var ev []Evento
		if ev, err = leggiEventi(data); err == nil {
			c.eventi = ev
			log.Printf("eventi: %d letti da %s", len(ev), c.path)
			return
		}
	}
	log.Printf("eventi: %s non va, tengo il calendario di prima: %v", c.path, err)
}

// leggiEventi controlla tutto il file: un errore e non si usa niente.
func leggiEventi(data []byte) ([]Evento, error) {
	var f struct {
		Eventi []Evento `json:"eventi"`
	}
	dec := json.NewDecoder(bytes.NewReader(data))
	dec.DisallowUnknownFields() // un campo scritto male si vede subito
	if err := dec.Decode(&f); err != nil {
		return nil, err
	}
	visti := map[string]bool{}
	var eng *Engine
	defer func() {
		if eng != nil {
			eng.L.Close()
		}
	}()
	for i := range f.Eventi {
		e := &f.Eventi[i]
		if err := e.controlla(); err != nil {
			return nil, fmt.Errorf("evento %q: %w", e.ID, err)
		}
		if visti[e.ID] {
			return nil, fmt.Errorf("evento %q: id ripetuto", e.ID)
		}
		visti[e.ID] = true
		if len(e.Regole) > 0 {
			if eng == nil {
				var err error
				if eng, err = newEngine(); err != nil {
					return nil, err
				}
			}
			r, err := eng.fromJSON(e.Regole)
			if err == nil {
				var v interface{ String() string }
				if v, err = eng.call("regole_valida", r, lua.LBool(e.Modo == "")); err == nil && v.String() != "" {
					err = fmt.Errorf("regole: %s", v.String())
				}
			}
			if err != nil {
				return nil, fmt.Errorf("evento %q: %w", e.ID, err)
			}
		}
	}
	return f.Eventi, nil
}

func (e *Evento) controlla() error {
	var err error
	if !idEvento.MatchString(e.ID) {
		return fmt.Errorf("id: lettere minuscole, cifre e _")
	}
	if _, ok := modes[e.ID]; ok {
		return fmt.Errorf("id: %q è già una coda normale", e.ID)
	}
	propria, ok := tipiEvento[e.Tipo]
	if !ok {
		return fmt.Errorf("tipo: mod, torneo, sfida o xp")
	}
	if e.Nome == "" {
		return fmt.Errorf("manca il nome")
	}
	if e.da, err = time.ParseInLocation("2006-01-02 15:04", e.Da, roma); err != nil {
		return fmt.Errorf("da: %w", err)
	}
	if e.a, err = time.ParseInLocation("2006-01-02 15:04", e.A, roma); err != nil {
		return fmt.Errorf("a: %w", err)
	}
	if !e.a.After(e.da) {
		return fmt.Errorf("a viene prima di da")
	}
	if e.Ogni < 0 {
		return fmt.Errorf("ogni: settimane, 0 = una volta sola")
	}
	if e.Ogni > 0 && e.a.Sub(e.da) > time.Duration(e.Ogni)*7*24*time.Hour {
		return fmt.Errorf("dura più di %d settimane: si accavallerebbe con la volta dopo", e.Ogni)
	}
	if e.Fino != "" {
		if e.fino, err = time.ParseInLocation("2006-01-02", e.Fino, roma); err != nil {
			return fmt.Errorf("fino: %w", err)
		}
		e.fino = e.fino.AddDate(0, 0, 1) // compreso quel giorno
	}
	if propria {
		if _, ok := modes[e.Modo]; !ok {
			return fmt.Errorf("modo: 1v1, 2v2 o ffa")
		}
		if e.Coda != "" {
			return fmt.Errorf("coda: un evento con la coda sua non sta su un'altra")
		}
	} else {
		if e.Coda == "" {
			e.Coda = "2v2"
		}
		if _, ok := modes[e.Coda]; !ok {
			return fmt.Errorf("coda: 1v1, 2v2 o ffa")
		}
		if e.Modo != "" {
			return fmt.Errorf("modo solo per i modificatori (tipo mod), che hanno la coda loro")
		}
		// le regole che cambiano la partita su una coda normale la cambierebbero a
		// tutti: lì passa solo il tetto ai livelli (regole.CODA_NORMALE, leggiEventi)
	}
	return nil
}

// volta k dell'evento: inizio e fine (AddDate tiene l'ora anche col cambio dell'ora legale)
func (e *Evento) volta(k int) (time.Time, time.Time, bool) {
	if k > 0 && e.Ogni == 0 {
		return time.Time{}, time.Time{}, false
	}
	da, a := e.da.AddDate(0, 0, 7*e.Ogni*k), e.a.AddDate(0, 0, 7*e.Ogni*k)
	if !e.fino.IsZero() && !da.Before(e.fino) {
		return da, a, false
	}
	return da, a, true
}

func (e *Evento) occorrenza(da, a time.Time) Occorrenza {
	o := Occorrenza{
		ID: e.ID + "-" + da.In(roma).Format("20060102"), Evento: e.ID, Tipo: e.Tipo,
		Nome: e.Nome, Riga: e.Riga, Da: da.Unix(), A: a.Unix(),
		Regole: e.Regole, Premi: e.Premi, Obiettivo: e.Obiettivo,
	}
	if e.Modo != "" {
		o.Coda, o.Modo = o.ID, e.Modo
	} else {
		o.Coda, o.Modo = e.Coda, e.Coda
	}
	o.Giocatori = modes[o.Modo].Players
	return o
}

// Occorrenze: quelle in corso adesso e quelle che cominciano nei prossimi
// giorniAvanti giorni, in ordine di inizio.
func (c *Calendario) Occorrenze() []Occorrenza {
	c.aggiorna()
	c.mu.Lock()
	eventi, now := c.eventi, c.now()
	c.mu.Unlock()
	limite := now.AddDate(0, 0, giorniAvanti)
	out := []Occorrenza{}
	for i := range eventi {
		e := &eventi[i]
		// salta le volte già finite senza contarle una a una
		k := 0
		if e.Ogni > 0 && now.After(e.a) {
			k = int(now.Sub(e.a)/(time.Duration(e.Ogni)*7*24*time.Hour)) - 1
			k = max(k, 0)
		}
		for ; ; k++ {
			da, a, ok := e.volta(k)
			if !ok || da.After(limite) {
				break
			}
			if !a.After(now) {
				continue
			}
			o := e.occorrenza(da, a)
			if dopo, _, ok := e.volta(k + 1); ok {
				o.Torna = dopo.Unix()
			}
			out = append(out, o)
		}
	}
	sort.SliceStable(out, func(i, j int) bool {
		if out[i].Da != out[j].Da {
			return out[i].Da < out[j].Da
		}
		return out[i].ID < out[j].ID
	})
	return out
}

// Coda trova la coda di un evento in corso dal suo id (evento-AAAAMMGG).
func (c *Calendario) Coda(id string) (Mode, bool) {
	now := c.now().Unix()
	for _, o := range c.Occorrenze() {
		if o.Coda == id && o.Modo != o.Coda && o.Da <= now && now < o.A {
			return Mode{Name: o.ID, Players: o.Giocatori, Sim: o.Modo, Regole: o.Regole}, true
		}
	}
	return Mode{}, false
}
