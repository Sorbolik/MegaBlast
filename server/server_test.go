package main

import (
	"context"
	"encoding/json"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/coder/websocket"
)

func TestSimFromEmbeddedLua(t *testing.T) {
	sim, err := NewSim(42, "isole")
	if err != nil {
		t.Fatal(err)
	}
	defer sim.Close()
	for i := 0; i < 120; i++ {
		if err := sim.Step(Input{}); err != nil {
			t.Fatal(err)
		}
	}
	var st struct {
		Phase string `json:"phase"`
		Cur   int    `json:"cur"`
		R     []struct {
			X, Y float64
			HP   int  `json:"hp"`
			G    bool `json:"g"`
		} `json:"r"`
	}
	if err := json.Unmarshal([]byte(sim.Snapshot()), &st); err != nil {
		t.Fatalf("snapshot non è JSON valido: %v\n%s", err, sim.Snapshot())
	}
	if st.Phase != "aim" || st.Cur != 1 || len(st.R) != 2 || !st.R[0].G || st.R[0].HP != 100 {
		t.Fatalf("stato inatteso: %+v", st)
	}
	if err := sim.Step(Input{Fire: true, Angle: 1.0, Power: 0.6}); err != nil {
		t.Fatal(err)
	}
	found := false
	for i := 0; i < 600 && !found; i++ {
		sim.Step(Input{})
		for _, e := range sim.Events() {
			var ev map[string]any
			if err := json.Unmarshal([]byte(e), &ev); err != nil {
				t.Fatalf("evento non è JSON valido: %v\n%s", err, e)
			}
			if ev["type"] == "explosion" || ev["type"] == "miss" {
				found = true
			}
		}
	}
	if !found {
		t.Fatal("il missile non è mai esploso")
	}
}

type testClient struct {
	t    *testing.T
	conn *websocket.Conn
	ctx  context.Context
}

func dial(t *testing.T, ctx context.Context, url string) *testClient {
	conn, _, err := websocket.Dial(ctx, url, nil)
	if err != nil {
		t.Fatal(err)
	}
	return &testClient{t: t, conn: conn, ctx: ctx}
}

// waitFor legge messaggi finché uno contiene want.
func (c *testClient) waitFor(want string) map[string]any {
	for {
		_, data, err := c.conn.Read(c.ctx)
		if err != nil {
			c.t.Fatalf("in attesa di %q: %v", want, err)
		}
		if strings.Contains(string(data), want) {
			var m map[string]any
			json.Unmarshal(data, &m)
			return m
		}
	}
}

func (c *testClient) send(msg string) {
	if err := c.conn.Write(c.ctx, websocket.MessageText, []byte(msg)); err != nil {
		c.t.Fatal(err)
	}
}

func TestOnlineMatch(t *testing.T) {
	lobby := &Lobby{ready: map[*Player]chan struct{}{}}
	srv := httptest.NewServer(httpHandler(lobby))
	defer srv.Close()
	url := "ws" + strings.TrimPrefix(srv.URL, "http") + "/ws"
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	a := dial(t, ctx, url)
	a.waitFor(`"wait"`)
	b := dial(t, ctx, url)
	sa := a.waitFor(`"start"`)
	sb := b.waitFor(`"start"`)
	if sa["you"].(float64) != 1 || sb["you"].(float64) != 2 || sa["seed"] != sb["seed"] {
		t.Fatalf("start inatteso: %v %v", sa, sb)
	}

	// Il giocatore 1 cammina: l'avversario riceve la nuova posizione
	first := b.waitFor(`"state"`)
	r0 := first["r"].([]any)[0].(map[string]any)
	x0 := r0["x"].(float64)
	// lo stato porta casse, schegge e colpi delle armi delle casse (all'inizio nessuno)
	if _, ok := first["c"].([]any); !ok || r0["ag"] != 0.0 || r0["ap"] != 0.0 {
		t.Fatalf("stato senza casse o colpi: %v", first)
	}
	a.send(`{"t":"in","l":false,"r":true}`)
	time.Sleep(500 * time.Millisecond)
	a.send(`{"t":"in","l":false,"r":false}`)
	moved := false
	for i := 0; i < 40 && !moved; i++ {
		st := b.waitFor(`"state"`)
		x := st["r"].([]any)[0].(map[string]any)["x"].(float64)
		moved = x > x0+10
	}
	if !moved {
		t.Fatal("il movimento del giocatore 1 non arriva al giocatore 2")
	}

	// Il globo del teletrasporto parte senza chiudere il turno
	a.send(`{"t":"fire","a":1.4,"p":0.3,"w":"teleport"}`)
	if orb := b.waitFor(`"orb"`); orb["robot"].(float64) != 1 {
		t.Fatalf("globo del robot sbagliato: %v", orb)
	}

	// Senza colpi l'Uovo di Fiamma non parte (resta il turno del giocatore 1).
	// Il giocatore 2 non può sparare fuori turno; il giocatore 1 sì
	a.send(`{"t":"fire","a":1.0,"p":0.6,"w":"grenade"}`)
	b.send(`{"t":"fire","a":2.0,"p":0.5}`)
	a.send(`{"t":"fire","a":1.0,"p":0.6}`)
	ev := b.waitFor(`"fire"`)
	if ev["robot"].(float64) != 1 {
		t.Fatalf("ha sparato il robot sbagliato: %v", ev)
	}
	turn := b.waitFor(`"turn"`)
	if turn["robot"].(float64) != 2 {
		t.Fatalf("il turno non passa al giocatore 2: %v", turn)
	}

	// Se un giocatore esce, l'altro viene avvisato
	a.conn.Close(websocket.StatusNormalClosure, "")
	b.waitFor(`"left"`)
}
