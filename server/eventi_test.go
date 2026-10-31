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
const calendarioProva = `{"eventi": [
	{"id": "maglio", "tipo": "mod", "nome": "2V2 SOLO MAGLIO", "riga": "Una sola arma",
	 "da": "2026-11-02 10:00", "a": "2026-11-04 23:59", "ogni": 2,
	 "modo": "2v2", "regole": {"armi": ["punch", "mallet"], "casse": 2},
	 "premi": [{"testo": "Badge", "fino": 100}]},
	{"id": "torneo", "tipo": "torneo", "nome": "TORNEO 2V2",
	 "da": "2026-11-06 18:00", "a": "2026-11-08 22:00", "ogni": 1, "fino": "2026-11-13"}
]}`

func calendario(t *testing.T, testo string, ora string) *Calendario {
	t.Helper()
	p := filepath.Join(t.TempDir(), "eventi.json")
	if err := os.WriteFile(p, []byte(testo), 0o644); err != nil {
		t.Fatal(err)
	}
	now, err := time.ParseInLocation("2006-01-02 15:04", ora, roma)
	if err != nil {
		t.Fatal(err)
	}
	c := &Calendario{path: p, now: func() time.Time { return now }}
	c.aggiorna()
	return c
}

func ids(oo []Occorrenza) string {
	s := []string{}
	for _, o := range oo {
		s = append(s, o.ID)
	}
	return strings.Join(s, " ")
}

// Le ripetizioni si espandono per i prossimi 14 giorni, con l'id del giorno
// d'inizio, "torna" e la coda giusta; il Torneo si ferma a "fino".
func TestEventiRipetizioni(t *testing.T) {
	c := calendario(t, calendarioProva, "2026-11-03 12:00")
	oo := c.Occorrenze()
	if got, want := ids(oo), "maglio-20261102 torneo-20261106 torneo-20261113 maglio-20261116"; got != want {
		t.Fatalf("occorrenze %q, volevo %q", got, want)
	}
	m := oo[0]
	if m.Coda != "maglio-20261102" || m.Modo != "2v2" || m.Giocatori != 4 || m.Torna != oo[3].Da {
		t.Fatalf("modificatore sbagliato: %+v", m)
	}
	if tr := oo[1]; tr.Coda != "2v2" || tr.Regole != nil || tr.Torna != oo[2].Da {
		t.Fatalf("torneo sbagliato: %+v", tr)
	}
	if oo[2].Torna != 0 {
		t.Fatalf("dopo fino il torneo non torna: %+v", oo[2])
	}
	// col cambio dell'ora (25 ottobre) l'evento comincia sempre alle 10 di Roma
	if h := time.Unix(oo[3].Da, 0).In(roma).Hour(); h != 10 {
		t.Fatalf("ora d'inizio %d", h)
	}
	// la coda c'è solo mentre l'evento è in corso
	if mode, ok := c.Coda("maglio-20261102"); !ok || mode.Players != 4 || mode.Sim != "2v2" || !strings.Contains(string(mode.Regole), "mallet") {
		t.Fatalf("coda dell'evento: %+v %v", mode, ok)
	}
	if _, ok := c.Coda("maglio-20261116"); ok {
		t.Fatal("la coda di un evento non ancora cominciato non c'è")
	}
	if _, ok := c.Coda("torneo-20261106"); ok {
		t.Fatal("il torneo non ha una coda sua")
	}
	// molto dopo: si salta alle volte giuste senza contarle tutte
	c = calendario(t, calendarioProva, "2028-01-04 12:00")
	if got := ids(c.Occorrenze()); !strings.HasPrefix(got, "maglio-") || strings.Contains(got, "torneo") {
		t.Fatalf("nel 2028 %q", got)
	}
}

// Un file sbagliato non passa, e il calendario buono resta.
func TestEventiFileSbagliato(t *testing.T) {
	sbagliati := map[string]string{
		"regola sconosciuta": `{"eventi":[{"id":"x","tipo":"mod","nome":"X","da":"2026-11-02 10:00","a":"2026-11-03 10:00","modo":"2v2","regole":{"vento":3}}]}`,
		"arma sconosciuta":   `{"eventi":[{"id":"x","tipo":"mod","nome":"X","da":"2026-11-02 10:00","a":"2026-11-03 10:00","modo":"2v2","regole":{"armi":["bazooka"]}}]}`,
		"regole sul torneo":  `{"eventi":[{"id":"x","tipo":"torneo","nome":"X","da":"2026-11-02 10:00","a":"2026-11-03 10:00","regole":{"casse":2}}]}`,
		"modo che non c'è":   `{"eventi":[{"id":"x","tipo":"mod","nome":"X","da":"2026-11-02 10:00","a":"2026-11-03 10:00","modo":"3v3"}]}`,
		"si accavalla":       `{"eventi":[{"id":"x","tipo":"xp","nome":"X","da":"2026-11-02 10:00","a":"2026-11-10 10:00","ogni":1}]}`,
		"campo scritto male": `{"eventi":[{"id":"x","tipo":"xp","nome":"X","da":"2026-11-02 10:00","a":"2026-11-03 10:00","ogi":1}]}`,
		"id ripetuto":        `{"eventi":[{"id":"x","tipo":"xp","nome":"X","da":"2026-11-02 10:00","a":"2026-11-03 10:00"},{"id":"x","tipo":"xp","nome":"X","da":"2026-11-05 10:00","a":"2026-11-06 10:00"}]}`,
		"id di una coda":     `{"eventi":[{"id":"2v2","tipo":"xp","nome":"X","da":"2026-11-02 10:00","a":"2026-11-03 10:00"}]}`,
		"a prima di da":      `{"eventi":[{"id":"x","tipo":"xp","nome":"X","da":"2026-11-02 10:00","a":"2026-11-01 10:00"}]}`,
	}
	for nome, testo := range sbagliati {
		if _, err := leggiEventi([]byte(testo)); err == nil {
			t.Errorf("%s: passato", nome)
		}
	}
	c := calendario(t, calendarioProva, "2026-11-03 12:00")
	os.WriteFile(c.path, []byte(sbagliati["arma sconosciuta"]), 0o644)
	future := time.Now().Add(time.Minute)
	os.Chtimes(c.path, future, future)
	c.guardato = time.Time{}
	if n := len(c.Occorrenze()); n != 4 {
		t.Fatalf("con un file sbagliato restano %d occorrenze, volevo le 4 di prima", n)
	}
}

// GET /eventi, poi una partita nella coda dell'evento: lo start porta le
// regole e la scelta delle armi offre solo quelle dell'evento.
func TestEventoOnline(t *testing.T) {
	cfg := DefaultConfig()
	cfg.DraftTicks = tickRate / 2
	srvx := NewServer(cfg)
	srvx.eventi = calendario(t, calendarioProva, "2026-11-03 12:00")
	srv := httptest.NewServer(srvx.Handler())
	t.Cleanup(srv.Close)

	res, err := http.Get(srv.URL + "/eventi")
	if err != nil {
		t.Fatal(err)
	}
	body, _ := io.ReadAll(res.Body)
	res.Body.Close()
	var cal struct {
		Ora    int64        `json:"ora"`
		Eventi []Occorrenza `json:"eventi"`
	}
	if err := json.Unmarshal(body, &cal); err != nil || len(cal.Eventi) != 4 || res.Header.Get("Access-Control-Allow-Origin") != "*" {
		t.Fatalf("GET /eventi: %v %s", err, body)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	url := "ws" + strings.TrimPrefix(srv.URL, "http") + "/ws"
	finito := dial(t, ctx, url)
	finito.send(`{"t":"hello","v":7,"mode":"maglio-20261116"}`)
	if m := finito.waitFor(`"error"`); m["e"] != "evento" {
		t.Fatalf("coda di un evento non in corso: %v", m)
	}

	c := make([]*testClient, 4)
	for i := range c {
		c[i] = dial(t, ctx, url)
		c[i].send(`{"t":"hello","v":7,"mode":"maglio-20261102"}`)
	}
	d := c[0].waitFor(`"draft"`)
	for _, fila := range []string{"offer", "offer2"} {
		for _, w := range d[fila].([]any) {
			if w != "punch" && w != "mallet" {
				t.Fatalf("nella scelta dell'evento c'è %v (%s)", w, fila)
			}
		}
	}
	s := c[0].waitFor(`"start"`)
	r, _ := s["regole"].(map[string]any)
	if s["mode"] != "maglio-20261102" || r == nil || r["casse"].(float64) != 2 {
		t.Fatalf("start senza le regole dell'evento: %v", s)
	}
}
