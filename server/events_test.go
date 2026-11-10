package main

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

// The test calendar: a 2v2 modifier every other week from Monday to Wednesday
// (Sergio's example) and a Torneo on the 2v2 queue.
const testCalendar = `{"eventi": [
	{"id": "maglio", "tipo": "mod", "nome": "2V2 SOLO MAGLIO", "riga": "Una sola arma",
	 "da": "2026-11-02 10:00", "a": "2026-11-04 23:59", "ogni": 2,
	 "modo": "2v2", "regole": {"armi": ["punch", "mallet"], "casse": 2},
	 "premi": [{"testo": "Badge", "fino": 100}]},
	{"id": "torneo", "tipo": "torneo", "nome": "TORNEO 2V2",
	 "da": "2026-11-06 18:00", "a": "2026-11-08 22:00", "ogni": 1, "fino": "2026-11-13"}
]}`

func calendar(t *testing.T, text string, at string) *Calendar {
	t.Helper()
	p := filepath.Join(t.TempDir(), "eventi.json")
	if err := os.WriteFile(p, []byte(text), 0o644); err != nil {
		t.Fatal(err)
	}
	now, err := time.ParseInLocation("2006-01-02 15:04", at, rome)
	if err != nil {
		t.Fatal(err)
	}
	c := &Calendar{path: p, now: func() time.Time { return now }}
	c.reload()
	return c
}

func ids(oo []Occurrence) string {
	s := []string{}
	for _, o := range oo {
		s = append(s, o.ID)
	}
	return strings.Join(s, " ")
}

// Repetitions are expanded for the next 14 days, with the id of the start day,
// "torna" and the right queue; the Torneo stops at "fino".
func TestEventRepeats(t *testing.T) {
	c := calendar(t, testCalendar, "2026-11-03 12:00")
	oo := c.Occurrences()
	if got, want := ids(oo), "maglio-20261102 torneo-20261106 torneo-20261113 maglio-20261116"; got != want {
		t.Fatalf("occurrences %q, wanted %q", got, want)
	}
	m := oo[0]
	if m.Queue != "maglio-20261102" || m.Teams != "2v2" || m.PlayerCount != 4 || m.Next != oo[3].From {
		t.Fatalf("wrong modifier: %+v", m)
	}
	if tr := oo[1]; tr.Queue != "2v2" || tr.Rules != nil || tr.Next != oo[2].From {
		t.Fatalf("wrong torneo: %+v", tr)
	}
	if oo[2].Next != 0 {
		t.Fatalf("after fino the torneo doesn't come back: %+v", oo[2])
	}
	// across the clock change (25 October) the event always starts at 10 Rome time
	if h := time.Unix(oo[3].From, 0).In(rome).Hour(); h != 10 {
		t.Fatalf("start hour %d", h)
	}
	// the queue exists only while the event is running
	if mode, ok := c.Queue("maglio-20261102"); !ok || mode.Players != 4 || mode.Sim != "2v2" || !strings.Contains(string(mode.Rules), "mallet") {
		t.Fatalf("event queue: %+v %v", mode, ok)
	}
	if _, ok := c.Queue("maglio-20261116"); ok {
		t.Fatal("the queue of an event not started yet must not exist")
	}
	if _, ok := c.Queue("torneo-20261106"); ok {
		t.Fatal("the torneo has no queue of its own")
	}
	// much later: it skips to the right times without counting them all
	c = calendar(t, testCalendar, "2028-01-04 12:00")
	if got := ids(c.Occurrences()); !strings.HasPrefix(got, "maglio-") || strings.Contains(got, "torneo") {
		t.Fatalf("in 2028 %q", got)
	}
}

// A wrong file doesn't pass, and the good calendar stays.
func TestEventsBadFile(t *testing.T) {
	wrong := map[string]string{
		"unknown rule":            `{"eventi":[{"id":"x","tipo":"mod","nome":"X","da":"2026-11-02 10:00","a":"2026-11-03 10:00","modo":"2v2","regole":{"vento":3}}]}`,
		"unknown weapon":          `{"eventi":[{"id":"x","tipo":"mod","nome":"X","da":"2026-11-02 10:00","a":"2026-11-03 10:00","modo":"2v2","regole":{"armi":["bazooka"]}}]}`,
		"cap too high":            `{"eventi":[{"id":"x","tipo":"torneo","nome":"X","da":"2026-11-02 10:00","a":"2026-11-03 10:00","regole":{"tetto":30}}]}`,
		"rules on the torneo":     `{"eventi":[{"id":"x","tipo":"torneo","nome":"X","da":"2026-11-02 10:00","a":"2026-11-03 10:00","regole":{"casse":2}}]}`,
		"mode that doesn't exist": `{"eventi":[{"id":"x","tipo":"mod","nome":"X","da":"2026-11-02 10:00","a":"2026-11-03 10:00","modo":"3v3"}]}`,
		"overlaps":                `{"eventi":[{"id":"x","tipo":"xp","nome":"X","da":"2026-11-02 10:00","a":"2026-11-10 10:00","ogni":1}]}`,
		"misspelled field":        `{"eventi":[{"id":"x","tipo":"xp","nome":"X","da":"2026-11-02 10:00","a":"2026-11-03 10:00","ogi":1}]}`,
		"repeated id":             `{"eventi":[{"id":"x","tipo":"xp","nome":"X","da":"2026-11-02 10:00","a":"2026-11-03 10:00"},{"id":"x","tipo":"xp","nome":"X","da":"2026-11-05 10:00","a":"2026-11-06 10:00"}]}`,
		"id of a queue":           `{"eventi":[{"id":"2v2","tipo":"xp","nome":"X","da":"2026-11-02 10:00","a":"2026-11-03 10:00"}]}`,
		"a before da":             `{"eventi":[{"id":"x","tipo":"xp","nome":"X","da":"2026-11-02 10:00","a":"2026-11-01 10:00"}]}`,
	}
	for name, text := range wrong {
		if _, err := readEvents([]byte(text)); err == nil {
			t.Errorf("%s: passed", name)
		}
	}
	c := calendar(t, testCalendar, "2026-11-03 12:00")
	os.WriteFile(c.path, []byte(wrong["unknown weapon"]), 0o644)
	future := time.Now().Add(time.Minute)
	os.Chtimes(c.path, future, future)
	c.checkedAt = time.Time{}
	if n := len(c.Occurrences()); n != 4 {
		t.Fatalf("with a wrong file %d occurrences remain, wanted the previous 4", n)
	}
}

// GET /eventi, then a match in the event's queue: start carries the rules and
// the weapon draft offers only the event's weapons.
func TestEventOnline(t *testing.T) {
	cfg := DefaultConfig()
	cfg.DraftTicks = tickRate / 2
	srvx := NewServer(cfg)
	srvx.events = calendar(t, testCalendar, "2026-11-03 12:00")
	srv := httptest.NewServer(srvx.Handler())
	t.Cleanup(srv.Close)

	res, err := http.Get(srv.URL + "/eventi")
	if err != nil {
		t.Fatal(err)
	}
	body, _ := io.ReadAll(res.Body)
	res.Body.Close()
	var cal struct {
		NowAt     int64        `json:"ora"`
		EventList []Occurrence `json:"eventi"`
	}
	if err := json.Unmarshal(body, &cal); err != nil || len(cal.EventList) != 4 || res.Header.Get("Access-Control-Allow-Origin") != "*" {
		t.Fatalf("GET /eventi: %v %s", err, body)
	}
	// the game's entry wants it always fresh, never a stored copy
	if c := res.Header.Get("Cache-Control"); c != "no-store" {
		t.Fatalf("GET /eventi: Cache-Control %q, want no-store", c)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	url := "ws" + strings.TrimPrefix(srv.URL, "http") + "/ws"
	finished := dial(t, ctx, url)
	finished.send(`{"t":"hello","v":9,"mode":"maglio-20261116"}`)
	if m := finished.waitFor(`"error"`); m["e"] != "evento" {
		t.Fatalf("queue of an event not running: %v", m)
	}

	c := make([]*testClient, 4)
	for i := range c {
		c[i] = dial(t, ctx, url)
		c[i].send(`{"t":"hello","v":9,"mode":"maglio-20261102"}`)
	}
	d := c[0].waitFor(`"draft"`)
	for _, row := range []string{"offer", "offer2"} {
		for _, w := range d[row].([]any) {
			if w != "punch" && w != "mallet" {
				t.Fatalf("the event draft contains %v (%s)", w, row)
			}
		}
	}
	s := c[0].waitFor(`"start"`)
	r, _ := s["regole"].(map[string]any)
	if s["mode"] != "maglio-20261102" || r == nil || r["casse"].(float64) != 2 {
		t.Fatalf("start without the event rules: %v", s)
	}
}

// From the panel: the server downloads the calendar, asks with the ETag (304
// if unchanged), says which version it took and, if it rejects it, why; a
// wrong version or the panel being down don't erase the good calendar.
func TestEventsFromPanel(t *testing.T) {
	version, text, down := `"3"`, testCalendar, false
	var taken, rejected string
	pannello := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if down {
			http.Error(w, "giù", http.StatusBadGateway)
			return
		}
		taken, rejected = r.URL.Query().Get("preso"), r.URL.Query().Get("errore")
		w.Header().Set("ETag", version)
		if r.Header.Get("If-None-Match") == version {
			w.WriteHeader(http.StatusNotModified)
			return
		}
		io.WriteString(w, text)
	}))
	t.Cleanup(pannello.Close)
	now, _ := time.ParseInLocation("2006-01-02 15:04", "2026-11-03 12:00", rome)
	c := &Calendar{path: pannello.URL + "/eventi.json", now: func() time.Time { return now }}
	cl := pannello.Client()
	c.download(cl)
	if n := len(c.Occurrences()); n != 4 || taken != "" {
		t.Fatalf("from the panel %d occurrences (took %q), wanted 4", n, taken)
	}
	c.download(cl) // unchanged: 304, and it says it took version 3
	if taken != "3" || rejected != "" || len(c.Occurrences()) != 4 {
		t.Fatalf("second time: took %q error %q", taken, rejected)
	}
	version, text = `"4"`, `{"eventi":[{"id":"x","tipo":"torneo","nome":"X","da":"2026-11-02 10:00","a":"2026-11-03 10:00","regole":{"casse":2}}]}`
	c.download(cl)
	c.download(cl)
	if taken != "4" || !strings.Contains(rejected, "casse") || len(c.Occurrences()) != 4 {
		t.Fatalf("wrong version: took %q error %q, %d occurrences", taken, rejected, len(c.Occurrences()))
	}
	down = true
	c.download(cl)
	if len(c.Occurrences()) != 4 || c.rete == "" {
		t.Fatalf("panel down: %d occurrences, network %q", len(c.Occurrences()), c.rete)
	}
	down, version, text = false, `"5"`, `{"eventi":[{"id":"x","tipo":"torneo","nome":"X","da":"2026-11-02 10:00","a":"2026-11-04 10:00","regole":{"tetto":15}}]}`
	c.download(cl)
	c.download(cl)
	oo := c.Occurrences()
	if taken != "5" || rejected != "" || len(oo) != 1 || string(oo[0].Rules) != `{"tetto":15}` || c.rete != "" {
		t.Fatalf("the cap on the Torneo: took %q error %q %+v", taken, rejected, oo)
	}
}

// Cloudflare turns the ETag weak (W/"6") when it compresses the answer: the
// server must still say it took version 6, or the panel stays yellow.
func TestEventsFromPanelWeakETag(t *testing.T) {
	var taken string
	pannello := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		taken = r.URL.Query().Get("preso")
		w.Header().Set("ETag", `W/"6"`)
		io.WriteString(w, testCalendar)
	}))
	t.Cleanup(pannello.Close)
	c := &Calendar{path: pannello.URL + "/eventi.json", now: time.Now}
	c.download(pannello.Client())
	c.download(pannello.Client())
	if taken != "6" {
		t.Fatalf("with a weak ETag the server says it took %q, wanted 6", taken)
	}
}
