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

// Il calendario della prova: un modificatore 2v2 a settimane alterne dal
// lunedì al mercoledì (l'esempio di Sergio) e un Torneo sulla coda 2v2.
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

// Le ripetizioni si espandono per i prossimi 14 giorni, con l'id del giorno
// d'inizio, "torna" e la coda giusta; il Torneo si ferma a "fino".
func TestEventRepeats(t *testing.T) {
	c := calendar(t, testCalendar, "2026-11-03 12:00")
	oo := c.Occurrences()
	if got, want := ids(oo), "maglio-20261102 torneo-20261106 torneo-20261113 maglio-20261116"; got != want {
		t.Fatalf("occorrenze %q, volevo %q", got, want)
	}
	m := oo[0]
	if m.Queue != "maglio-20261102" || m.Teams != "2v2" || m.PlayerCount != 4 || m.Next != oo[3].From {
		t.Fatalf("modificatore sbagliato: %+v", m)
	}
	if tr := oo[1]; tr.Queue != "2v2" || tr.Rules != nil || tr.Next != oo[2].From {
		t.Fatalf("torneo sbagliato: %+v", tr)
	}
	if oo[2].Next != 0 {
		t.Fatalf("dopo fino il torneo non torna: %+v", oo[2])
	}
	// col cambio dell'ora (25 ottobre) l'evento comincia sempre alle 10 di Roma
	if h := time.Unix(oo[3].From, 0).In(rome).Hour(); h != 10 {
		t.Fatalf("ora d'inizio %d", h)
	}
	// la coda c'è solo mentre l'evento è in corso
	if mode, ok := c.Queue("maglio-20261102"); !ok || mode.Players != 4 || mode.Sim != "2v2" || !strings.Contains(string(mode.Rules), "mallet") {
		t.Fatalf("coda dell'evento: %+v %v", mode, ok)
	}
	if _, ok := c.Queue("maglio-20261116"); ok {
		t.Fatal("la coda di un evento non ancora cominciato non c'è")
	}
	if _, ok := c.Queue("torneo-20261106"); ok {
		t.Fatal("il torneo non ha una coda sua")
	}
	// molto dopo: si salta alle volte giuste senza contarle tutte
	c = calendar(t, testCalendar, "2028-01-04 12:00")
	if got := ids(c.Occurrences()); !strings.HasPrefix(got, "maglio-") || strings.Contains(got, "torneo") {
		t.Fatalf("nel 2028 %q", got)
	}
}

// Un file sbagliato non passa, e il calendario buono resta.
func TestEventsBadFile(t *testing.T) {
	wrong := map[string]string{
		"regola sconosciuta": `{"eventi":[{"id":"x","tipo":"mod","nome":"X","da":"2026-11-02 10:00","a":"2026-11-03 10:00","modo":"2v2","regole":{"vento":3}}]}`,
		"arma sconosciuta":   `{"eventi":[{"id":"x","tipo":"mod","nome":"X","da":"2026-11-02 10:00","a":"2026-11-03 10:00","modo":"2v2","regole":{"armi":["bazooka"]}}]}`,
		"tetto troppo alto":  `{"eventi":[{"id":"x","tipo":"torneo","nome":"X","da":"2026-11-02 10:00","a":"2026-11-03 10:00","regole":{"tetto":30}}]}`,
		"regole sul torneo":  `{"eventi":[{"id":"x","tipo":"torneo","nome":"X","da":"2026-11-02 10:00","a":"2026-11-03 10:00","regole":{"casse":2}}]}`,
		"modo che non c'è":   `{"eventi":[{"id":"x","tipo":"mod","nome":"X","da":"2026-11-02 10:00","a":"2026-11-03 10:00","modo":"3v3"}]}`,
		"si accavalla":       `{"eventi":[{"id":"x","tipo":"xp","nome":"X","da":"2026-11-02 10:00","a":"2026-11-10 10:00","ogni":1}]}`,
		"campo scritto male": `{"eventi":[{"id":"x","tipo":"xp","nome":"X","da":"2026-11-02 10:00","a":"2026-11-03 10:00","ogi":1}]}`,
		"id ripetuto":        `{"eventi":[{"id":"x","tipo":"xp","nome":"X","da":"2026-11-02 10:00","a":"2026-11-03 10:00"},{"id":"x","tipo":"xp","nome":"X","da":"2026-11-05 10:00","a":"2026-11-06 10:00"}]}`,
		"id di una coda":     `{"eventi":[{"id":"2v2","tipo":"xp","nome":"X","da":"2026-11-02 10:00","a":"2026-11-03 10:00"}]}`,
		"a prima di da":      `{"eventi":[{"id":"x","tipo":"xp","nome":"X","da":"2026-11-02 10:00","a":"2026-11-01 10:00"}]}`,
	}
	for name, text := range wrong {
		if _, err := readEvents([]byte(text)); err == nil {
			t.Errorf("%s: passato", name)
		}
	}
	c := calendar(t, testCalendar, "2026-11-03 12:00")
	os.WriteFile(c.path, []byte(wrong["arma sconosciuta"]), 0o644)
	future := time.Now().Add(time.Minute)
	os.Chtimes(c.path, future, future)
	c.checkedAt = time.Time{}
	if n := len(c.Occurrences()); n != 4 {
		t.Fatalf("con un file sbagliato restano %d occorrenze, volevo le 4 di prima", n)
	}
}

// GET /eventi, poi una partita nella coda dell'evento: lo start porta le
// regole e la scelta delle armi offre solo quelle dell'evento.
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
		NowAt    int64        `json:"ora"`
		EventList []Occurrence `json:"eventi"`
	}
	if err := json.Unmarshal(body, &cal); err != nil || len(cal.EventList) != 4 || res.Header.Get("Access-Control-Allow-Origin") != "*" {
		t.Fatalf("GET /eventi: %v %s", err, body)
	}
	// l'ingresso del gioco lo vuole sempre fresco, mai una copia tenuta da parte
	if c := res.Header.Get("Cache-Control"); c != "no-store" {
		t.Fatalf("GET /eventi: Cache-Control %q, voglio no-store", c)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	url := "ws" + strings.TrimPrefix(srv.URL, "http") + "/ws"
	finished := dial(t, ctx, url)
	finished.send(`{"t":"hello","v":8,"mode":"maglio-20261116"}`)
	if m := finished.waitFor(`"error"`); m["e"] != "evento" {
		t.Fatalf("coda di un evento non in corso: %v", m)
	}

	c := make([]*testClient, 4)
	for i := range c {
		c[i] = dial(t, ctx, url)
		c[i].send(`{"t":"hello","v":8,"mode":"maglio-20261102"}`)
	}
	d := c[0].waitFor(`"draft"`)
	for _, row := range []string{"offer", "offer2"} {
		for _, w := range d[row].([]any) {
			if w != "punch" && w != "mallet" {
				t.Fatalf("nella scelta dell'evento c'è %v (%s)", w, row)
			}
		}
	}
	s := c[0].waitFor(`"start"`)
	r, _ := s["regole"].(map[string]any)
	if s["mode"] != "maglio-20261102" || r == nil || r["casse"].(float64) != 2 {
		t.Fatalf("start senza le regole dell'evento: %v", s)
	}
}

// Dal pannello: il server scarica il calendario, chiede con l'ETag (304 se non
// è cambiato), dice quale versione ha preso e, se la rifiuta, perché; una
// versione sbagliata o il pannello giù non cancellano il calendario buono.
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
		t.Fatalf("dal pannello %d occorrenze (preso %q), volevo 4", n, taken)
	}
	c.download(cl) // non è cambiato: 304, e dice che ha preso la 3
	if taken != "3" || rejected != "" || len(c.Occurrences()) != 4 {
		t.Fatalf("seconda volta: preso %q errore %q", taken, rejected)
	}
	version, text = `"4"`, `{"eventi":[{"id":"x","tipo":"torneo","nome":"X","da":"2026-11-02 10:00","a":"2026-11-03 10:00","regole":{"casse":2}}]}`
	c.download(cl)
	c.download(cl)
	if taken != "4" || !strings.Contains(rejected, "casse") || len(c.Occurrences()) != 4 {
		t.Fatalf("versione sbagliata: preso %q errore %q, %d occorrenze", taken, rejected, len(c.Occurrences()))
	}
	down = true
	c.download(cl)
	if len(c.Occurrences()) != 4 || c.rete == "" {
		t.Fatalf("pannello giù: %d occorrenze, rete %q", len(c.Occurrences()), c.rete)
	}
	down, version, text = false, `"5"`, `{"eventi":[{"id":"x","tipo":"torneo","nome":"X","da":"2026-11-02 10:00","a":"2026-11-04 10:00","regole":{"tetto":15}}]}`
	c.download(cl)
	c.download(cl)
	oo := c.Occurrences()
	if taken != "5" || rejected != "" || len(oo) != 1 || string(oo[0].Rules) != `{"tetto":15}` || c.rete != "" {
		t.Fatalf("il tetto sul Torneo: preso %q errore %q %+v", taken, rejected, oo)
	}
}
