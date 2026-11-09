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
	_ "time/tzdata" // event times are Rome times even on a server without time zones
)

// The event calendar (docs/server.md, "Eventi"): Sergio makes it in the
// events panel (strumenti/eventi, a Cloudflare Worker) and the server
// downloads it every 30 seconds (go run ./server -eventi https://…/eventi.json),
// or reads it from a JSON file (-eventi eventi.json) that it reloads by itself
// when it changes. An event is a template with its window and, optionally, a
// repetition: every N weeks until a date or forever. The server expands it
// into the occurrences of the next few days, each with its own id
// (event-YYYYMMDD), and gives them to the game with GET /eventi.
//
// An event either sits on a normal queue (Torneo, Sfida, XP: it counts for the
// matches of that queue) or has a queue of its own (modifier: "modo" says the
// teams, "regole" what changes, sim/rules.lua). The player only picks the
// queue: a match counts for all the events attached to its queue.
//
//	{"eventi": [{
//	  "id": "maglio", "tipo": "mod", "nome": "2V2 SOLO MAGLIO",
//	  "riga": "Una sola arma, colpi che fanno volare.",
//	  "da": "2026-11-02 10:00", "a": "2026-11-04 23:59", "ogni": 2, "fino": "2027-01-31",
//	  "modo": "2v2", "regole": {"armi": ["punch", "mallet"]},  (on a normal queue only {"tetto": 15})
//	  "premi": [{"testo": "Badge Maglio", "fino": 100}]
//	}]}
//
// The server passes "premi" and "obiettivo" through as they are: the game reads them.

// How many days ahead the server expands repetitions (the two strips of the board).
const daysAhead = 14

var rome = func() *time.Location {
	l, err := time.LoadLocation("Europe/Rome")
	if err != nil {
		panic(err)
	}
	return l
}()

// Event kinds: those with their own queue and those sitting on a normal queue.
var eventKinds = map[string]bool{"mod": true, "torneo": false, "sfida": false, "xp": false}

var eventID = regexp.MustCompile(`^[a-z0-9_]{1,32}$`)

// Event is how Sergio writes it in the file.
type Event struct {
	ID      string          `json:"id"`
	Kind    string          `json:"tipo"`
	Title   string          `json:"nome"`
	Line    string          `json:"riga"`
	From    string          `json:"da"`   // "2026-11-02 10:00", Rome time
	A       string          `json:"a"`    // end of the first window
	Every   int             `json:"ogni"` // weeks between one time and the next, 0 = only once
	Until   string          `json:"fino"` // "2027-01-31": the last day it can start again; empty = forever
	Teams   string          `json:"modo"` // own queue: the teams (1v1, 2v2, ffa)
	Queue   string          `json:"coda"` // normal queue it sits on (usually 2v2)
	Rules   json.RawMessage `json:"regole"`
	Rewards json.RawMessage `json:"premi"`
	Goal    json.RawMessage `json:"obiettivo"`

	da, a, until time.Time
}

// Occurrence is one time of an event, as the game sees it.
type Occurrence struct {
	ID          string          `json:"id"`
	Event       string          `json:"evento"`
	Kind        string          `json:"tipo"`
	Title       string          `json:"nome"`
	Line        string          `json:"riga,omitempty"`
	From        int64           `json:"da"`              // Unix seconds
	A           int64           `json:"a"`               // Unix seconds
	Next        int64           `json:"torna,omitempty"` // the next time, if any
	Queue       string          `json:"coda"`            // the queue to ask for in hello to play it
	Teams       string          `json:"modo"`            // the teams of the match
	PlayerCount int             `json:"giocatori"`
	Rules       json.RawMessage `json:"regole,omitempty"`
	Rewards     json.RawMessage `json:"premi,omitempty"`
	Goal        json.RawMessage `json:"obiettivo,omitempty"`
}

// How often the server asks the panel for the calendar.
const panelPoll = 30 * time.Second

// Calendar reads the events file and reloads it when it changes, or downloads
// it from the panel.
type Calendar struct {
	path string
	now  func() time.Time

	mu        sync.Mutex
	events    []Event
	modTime   time.Time
	checkedAt time.Time

	// from the panel: the version taken (ETag), the error if the server rejected
	// it (the panel shows it to Sergio) and the last network problem
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

// download asks the panel for the calendar. In the request it says which
// version it took and, if it rejected it, why: the panel shows it to Sergio.
// As with the file, a wrong calendar doesn't replace the good one, and if the
// panel doesn't answer the previous one stays.
func (c *Calendar) download(client *http.Client) {
	c.mu.Lock()
	u, etag := c.path, c.version
	if c.version != "" {
		u += "?" + url.Values{"preso": {strings.Trim(strings.TrimPrefix(c.version, "W/"), `"`)}, "errore": {c.rejected}}.Encode()
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

// problem logs a network problem with the panel only when it changes
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

// reload reads the file again if it changed (at most every two seconds). A
// wrong file doesn't erase the good calendar: the previous one stays and the
// error goes to the log.
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

// readEvents checks the whole file: one error and nothing is used.
func readEvents(data []byte) ([]Event, error) {
	var f struct {
		EventList []Event `json:"eventi"`
	}
	dec := json.NewDecoder(bytes.NewReader(data))
	dec.DisallowUnknownFields() // a misspelled field shows up at once
	if err := dec.Decode(&f); err != nil {
		return nil, err
	}
	seen := map[string]bool{}
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
			msg, err := rulesValid(e.Rules, e.Teams == "")
			if err == nil && msg != "" {
				err = fmt.Errorf("regole: %s", msg)
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
		e.until = e.until.AddDate(0, 0, 1) // that day included
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
		// rules that change the match on a normal queue would change it for everyone:
		// only the level cap gets through there (rules.CODA_NORMALE, readEvents)
	}
	return nil
}

// time k of the event: start and end (AddDate keeps the hour across daylight saving changes)
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

// Occurrences: those running now and those starting in the next daysAhead
// days, in order of start.
func (c *Calendar) Occurrences() []Occurrence {
	c.reload()
	c.mu.Lock()
	events, now := c.events, c.now()
	c.mu.Unlock()
	limit := now.AddDate(0, 0, daysAhead)
	out := []Occurrence{}
	for i := range events {
		e := &events[i]
		// skip the times already over without counting them one by one
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

// Queue finds the queue of a running event from its id (event-YYYYMMDD).
func (c *Calendar) Queue(id string) (Mode, bool) {
	now := c.now().Unix()
	for _, o := range c.Occurrences() {
		if o.Queue == id && o.Teams != o.Queue && o.From <= now && now < o.A {
			return Mode{Name: o.ID, Players: o.PlayerCount, Sim: o.Teams, Rules: o.Rules}, true
		}
	}
	return Mode{}, false
}
