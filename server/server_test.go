package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http/httptest"
	"reflect"
	"strings"
	"testing"
	"time"

	"github.com/coder/websocket"
	lua "github.com/yuin/gopher-lua"
)

func newTestSim(t testing.TB, seed int64, mapID string) *Sim {
	e, err := newEngine()
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(e.L.Close)
	sim, err := e.NewSim(seed, mapID, lua.LNil, false)
	if err != nil {
		t.Fatal(err)
	}
	return sim
}

// Senza mappa la sceglie il seed fra quelle delle partite (maps.ROTATION):
// lo stesso seed dà sempre la stessa, e le escono tutte.
func TestSimPicksMapFromSeed(t *testing.T) {
	seen := map[string]bool{}
	for seed := int64(1); seed <= 4; seed++ {
		m := newTestSim(t, seed, "").Map()
		if m != newTestSim(t, seed, "").Map() {
			t.Fatalf("seed %d: mappa diversa a parità di seed", seed)
		}
		seen[m] = true
	}
	if !seen["forgia"] || !seen["crogiolo"] {
		t.Fatalf("mappe uscite: %v", seen)
	}
}

func TestSimFromEmbeddedLua(t *testing.T) {
	sim := newTestSim(t, 42, "crogiolo")
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
			MH   int  `json:"mh"`
			G    bool `json:"g"`
		} `json:"r"`
	}
	if err := json.Unmarshal(sim.Snapshot(), &st); err != nil {
		t.Fatalf("snapshot non è JSON valido: %v\n%s", err, sim.Snapshot())
	}
	if st.Phase != "aim" || st.Cur != 1 || len(st.R) != 2 || !st.R[0].G || st.R[0].HP != st.R[0].MH || st.R[0].MH == 0 {
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
			if err := json.Unmarshal(e, &ev); err != nil {
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

// Al primo turno, lanciato il globo di partenza, i globi guadagnati attaccando
// si lanciano lo stesso anche sul server, e lo stato li porta al client (te).
func TestEarnedTeleportsFirstTurn(t *testing.T) {
	sim := newTestSim(t, 42, "forgia")
	orbs := func() int {
		var st struct {
			O []json.RawMessage `json:"o"`
		}
		if err := json.Unmarshal(sim.Snapshot(), &st); err != nil {
			t.Fatal(err)
		}
		return len(st.O)
	}
	tele := Input{Fire: true, Angle: 1.5, Power: 0.2, Weapon: "teleport"}
	steps := []Input{{}, tele, tele, {Fire: true, Angle: 1.0, Power: 0.6}}
	for _, in := range steps {
		if err := sim.Step(in); err != nil {
			t.Fatal(err)
		}
	}
	if n := orbs(); n != 1 {
		t.Fatalf("al primo turno un solo globo di partenza: %d in volo", n)
	}
	var st struct {
		TE int `json:"te"`
	}
	json.Unmarshal(sim.Snapshot(), &st)
	if st.TE != 2 {
		t.Fatalf("attaccando subito si guadagnano due globi, stato te=%d", st.TE)
	}
	sim.Step(tele)
	sim.Step(tele)
	if n := orbs(); n != 3 {
		t.Fatalf("i due globi guadagnati devono partire: %d in volo", n)
	}
}

// L'uncino del Rampino vola: nello stato c'è finché è in volo (gs, gx, gy), così
// online il client disegna il filo che si allunga; poi arriva l'evento "hook".
func TestHookShotInSnapshot(t *testing.T) {
	sim := newTestSim(t, 42, "forgia")
	for i := 0; i < 60; i++ {
		sim.Step(Input{})
	}
	sim.Events()
	if err := sim.Step(Input{Fire: true, Angle: 1.3, Power: 1, Weapon: "hook"}); err != nil {
		t.Fatal(err)
	}
	var st struct {
		R []struct {
			GS bool    `json:"gs"`
			GX float64 `json:"gx"`
			GY float64 `json:"gy"`
		} `json:"r"`
	}
	flying, ended := 0, false
	for i := 0; i < 60 && !ended; i++ {
		if err := json.Unmarshal(sim.Snapshot(), &st); err != nil {
			t.Fatal(err)
		}
		if st.R[0].GS && st.R[0].GY != 0 {
			flying++
		}
		sim.Step(Input{})
		for _, e := range sim.Events() {
			var ev map[string]any
			json.Unmarshal(e, &ev)
			if ev["type"] == "hook" {
				ended = true
			}
		}
	}
	if flying < 2 || !ended {
		t.Fatalf("l'uncino non vola (stati in volo %d, finito %v)", flying, ended)
	}
}

// Lo scambio del secondo attacco con un teletrasporto passa dal server come
// le armi (fire.w = "swap"): un globo in più e gli attacchi chiusi nello stato.
func TestSwapSecondAttack(t *testing.T) {
	sim := newTestSim(t, 42, "forgia")
	type stato struct {
		U int `json:"u"`
		R []struct {
			TL int `json:"tl"`
		} `json:"r"`
	}
	leggi := func() stato {
		var st stato
		if err := json.Unmarshal(sim.Snapshot(), &st); err != nil {
			t.Fatal(err)
		}
		return st
	}
	for i := 0; i < 20*60; i++ {
		sim.Step(Input{})
	}
	sim.Step(Input{Fire: true, Angle: 1.0, Power: 0.6})
	prima := leggi()
	sim.Step(Input{Fire: true, Weapon: "swap"})
	swapped := false
	for _, e := range sim.Events() {
		var ev map[string]any
		json.Unmarshal(e, &ev)
		if ev["type"] == "swap" {
			swapped = true
		}
	}
	dopo := leggi()
	if !swapped || dopo.R[0].TL != prima.R[0].TL+1 || dopo.U&3 != 3 {
		t.Fatalf("scambio non riuscito: evento %v, globi %d -> %d, attacchi %d", swapped, prima.R[0].TL, dopo.R[0].TL, dopo.U)
	}
}

// Uno stato Lua riusato deve dare la stessa partita di uno nuovo: la copia
// della mappa in net.lua non deve cambiare niente.
func TestEngineReuseIsDeterministic(t *testing.T) {
	play := func(sim *Sim) []byte {
		for i := 0; i < 300; i++ {
			in := Input{Right: i < 100}
			if i == 150 {
				in = Input{Fire: true, Angle: 0.4, Power: 0.8}
			}
			if err := sim.Step(in); err != nil {
				t.Fatal(err)
			}
			sim.Events()
		}
		return sim.Snapshot()
	}
	fresh := play(newTestSim(t, 7, "forgia"))
	e, err := newEngine()
	if err != nil {
		t.Fatal(err)
	}
	defer e.L.Close()
	for round := 0; round < 3; round++ {
		sim, err := e.NewSim(7, "forgia", lua.LNil, false)
		if err != nil {
			t.Fatal(err)
		}
		if got := play(sim); !sameJSON(got, fresh) {
			t.Fatalf("partita %d sullo stato riusato diversa:\n%s\n%s", round, got, fresh)
		}
	}
}

// sameJSON confronta due messaggi: l'ordine delle chiavi non conta.
func sameJSON(a, b []byte) bool {
	var x, y any
	return json.Unmarshal(a, &x) == nil && json.Unmarshal(b, &y) == nil && reflect.DeepEqual(x, y)
}

// testClient legge sempre, come un client vero: chi non legge viene
// disconnesso dal server quando la sua coda si riempie.
type testClient struct {
	t    *testing.T
	conn *websocket.Conn
	ctx  context.Context
	msgs chan []byte // chiuso quando la connessione cade
	err  error
}

func dial(t *testing.T, ctx context.Context, url string) *testClient {
	conn, _, err := websocket.Dial(ctx, url, nil)
	if err != nil {
		t.Fatal(err)
	}
	c := &testClient{t: t, conn: conn, ctx: ctx, msgs: make(chan []byte, 1<<16)}
	go func() {
		defer close(c.msgs)
		for {
			_, data, err := conn.Read(ctx)
			if err != nil {
				c.err = err
				return
			}
			c.msgs <- data
		}
	}()
	return c
}

// waitFor legge messaggi finché uno contiene want.
func (c *testClient) waitFor(want string) map[string]any {
	c.t.Helper()
	for data := range c.msgs {
		if strings.Contains(string(data), want) {
			var m map[string]any
			json.Unmarshal(data, &m)
			return m
		}
	}
	c.t.Fatalf("in attesa di %q: %v", want, c.err)
	return nil
}

// closed aspetta che il server chiuda la connessione.
func (c *testClient) closed() bool {
	for range c.msgs {
	}
	return c.err != nil
}

func (c *testClient) send(msg string) {
	if err := c.conn.Write(c.ctx, websocket.MessageText, []byte(msg)); err != nil {
		c.t.Fatal(err)
	}
}

func testServer(t *testing.T) string {
	cfg := DefaultConfig()
	cfg.ReconnectTicks = tickRate / 2 // mezzo secondo per tornare, per non far durare troppo le prove
	cfg.DraftTicks = tickRate         // e un secondo per scegliere l'arma
	srv := httptest.NewServer(NewServer(cfg).Handler())
	t.Cleanup(srv.Close)
	return "ws" + strings.TrimPrefix(srv.URL, "http") + "/ws"
}

// I giocatori di ogni coda sono quelli di config.MODES
func TestModesMatchConfig(t *testing.T) {
	e, err := newEngine()
	if err != nil {
		t.Fatal(err)
	}
	defer e.L.Close()
	for name, m := range modes {
		v, err := e.call("mode_players", lua.LString(m.Sim))
		list, ok := v.(*lua.LTable)
		if err != nil || !ok || list.Len() != m.Players {
			t.Fatalf("modalità %s: %d giocatori, config.MODES[%q] dice %v", name, m.Players, m.Sim, v)
		}
	}
}

func TestHelloWrongVersion(t *testing.T) {
	url := testServer(t)
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	c := dial(t, ctx, url)
	c.send(`{"t":"hello","v":1,"mode":"1v1"}`)
	if m := c.waitFor(`"error"`); m["e"] != "version" || m["v"].(float64) != protocolVersion {
		t.Fatalf("risposta inattesa: %v", m)
	}
	if !c.closed() {
		t.Fatal("la connessione doveva chiudersi")
	}
}

func TestResumeUnknownToken(t *testing.T) {
	url := testServer(t)
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	c := dial(t, ctx, url)
	c.send(`{"t":"hello","v":4,"tok":"n1.inventato"}`)
	if m := c.waitFor(`"error"`); m["e"] != "expired" || !c.closed() {
		t.Fatalf("risposta inattesa: %v", m)
	}
}

func TestOnlineMatch(t *testing.T) {
	url := testServer(t)
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	hello := `{"t":"hello","v":4,"mode":"1v1"}`
	a := dial(t, ctx, url)
	a.send(hello)
	a.waitFor(`"wait"`)
	b := dial(t, ctx, url)
	b.send(hello)

	// Prima la scelta delle armi: il giocatore 1 prende la prima primaria e la
	// seconda secondaria dei ventagli, il 2 non sceglie e allo scadere riceve
	// le prime libere
	d := a.waitFor(`"draft"`)
	if len(d["offer"].([]any)) != 3 || len(d["offer2"].([]any)) != 3 || len(d["players"].([]any)) != 2 || d["tok"] == "" {
		t.Fatalf("scelta inattesa: %v", d)
	}
	w := d["offer"].([]any)[0].(string)
	w2 := d["offer2"].([]any)[1].(string)
	a.send(`{"t":"pick","w":"` + w + `"}`)
	if d := b.waitFor(`"draft"`); d["you"].(float64) != 2 {
		t.Fatalf("scelta inattesa: %v", d)
	}
	if d := a.waitFor(`"draft"`); d["p"] != w {
		t.Fatalf("la scelta non torna a chi l'ha fatta: %v", d)
	}
	a.send(`{"t":"pick","w":"` + w2 + `"}`)
	if d := a.waitFor(`"draft"`); d["p2"] != w2 {
		t.Fatalf("la secondaria non torna a chi l'ha fatta: %v", d)
	}
	sa := a.waitFor(`"start"`)
	sb := b.waitFor(`"start"`)
	if sa["you"].(float64) != 1 || sb["you"].(float64) != 2 || sa["seed"] != sb["seed"] {
		t.Fatalf("start inatteso: %v %v", sa, sb)
	}

	// Il giocatore 1 cammina: l'avversario riceve la nuova posizione
	first := b.waitFor(`"state"`)
	r0 := first["r"].([]any)[0].(map[string]any)
	x0 := r0["x"].(float64)
	// lo stato porta casse, schegge e colpi: il giocatore 1 ha i colpi
	// (config.DRAFT_SHOTS, 2) della primaria scelta e la sua secondaria
	r1 := first["r"].([]any)[1].(map[string]any)
	colpi := func(r map[string]any) (n float64) {
		for _, k := range []string{"ag", "as", "ap", "ac"} {
			n += r[k].(float64)
		}
		return
	}
	key := map[string]string{"grenade": "ag", "shards": "as", "punch": "ap", "sniper": "ac"}[w]
	if _, ok := first["c"].([]any); !ok || r0[key] != 2.0 || colpi(r0) != 2 || colpi(r1) != 2 {
		t.Fatalf("stato senza casse o colpi scelti: %v", first)
	}
	if r0["sw"] != w2 || r1["sw"] != d["offer2"].([]any)[0].(string) {
		t.Fatalf("secondarie scelte sbagliate: %v %v", r0["sw"], r1["sw"])
	}
	// con la fisica di Blastron si cammina piano (28 px/s): un secondo basta
	a.send(`{"t":"in","l":false,"r":true}`)
	time.Sleep(1000 * time.Millisecond)
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
	a.send(`{"t":"fire","a":1.7,"p":0.3,"w":"teleport"}`)
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

	explosions := 0
	for st := b.waitFor(`"state"`); st["cur"].(float64) != 2; st = b.waitFor(`"state"`) {
	}
	b.send(`{"t":"fire","a":2.2,"p":0.7}`)
	for {
		ev := b.waitFor(`"ev"`)
		if ev["type"] == "explosion" {
			explosions++
		}
		if ev["type"] == "turn" {
			break
		}
	}

	// Chi cade può tornare col gettone: riceve di nuovo la partita e gli scavi
	a.conn.CloseNow()
	if m := b.waitFor(`"away"`); m["robot"].(float64) != 1 {
		t.Fatalf("away inatteso: %v", m)
	}
	a = dial(t, ctx, url)
	a.send(fmt.Sprintf(`{"t":"hello","v":4,"tok":%q}`, sa["tok"]))
	if m := a.waitFor(`"start"`); m["resume"] != true || m["you"].(float64) != 1 {
		t.Fatalf("ripresa inattesa: %v", m)
	}
	if m := a.waitFor(`"sync"`); len(m["x"].([]any)) < explosions || explosions == 0 {
		t.Fatalf("scavi mancanti (%d esplosioni): %v", explosions, m)
	}
	a.waitFor(`"state"`)
	b.waitFor(`"back"`)

	// Se non torna in tempo, l'altro viene avvisato e la partita finisce
	a.conn.CloseNow()
	b.waitFor(`"away"`)
	if m := b.waitFor(`"left"`); m["robot"].(float64) != 1 {
		t.Fatalf("left inatteso: %v", m)
	}
}

// 2 contro 2: ognuno prende quello che vuole, anche la stessa arma del
// compagno, e vede solo le sue scelte (Sergio, 30 ott); il Rampino ce l'hanno tutti
func TestTeamDraft(t *testing.T) {
	url := testServer(t)
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	var c [4]*testClient
	for i := range c {
		c[i] = dial(t, ctx, url)
		c[i].send(`{"t":"hello","v":4,"mode":"2v2"}`)
	}
	you := map[float64]*testClient{}
	var offer, offer2 []any
	for _, x := range c {
		d := x.waitFor(`"draft"`)
		you[d["you"].(float64)] = x
		offer, offer2 = d["offer"].([]any), d["offer2"].([]any)
		if d["p"] != "" || d["p2"] != "" || d["offer3"] != nil {
			t.Fatalf("draft iniziale inatteso: %v", d)
		}
	}
	p1, p3 := you[1], you[3]
	w1, s1 := offer[0].(string), offer2[0].(string)
	p1.send(`{"t":"pick","w":"` + w1 + `"}`)
	p3.send(`{"t":"pick","w":"` + w1 + `"}`) // la stessa del compagno: va bene
	p3.send(`{"t":"pick","w":"` + s1 + `"}`)
	if d := p1.waitFor(`"draft"`); d["p"] != w1 || d["p2"] != "" {
		t.Fatalf("p1 deve vedere solo la sua scelta: %v", d)
	}
	for {
		d := p3.waitFor(`"draft"`)
		if d["p"] == w1 && d["p2"] == s1 {
			break
		}
	}
	st := p1.waitFor(`"start"`)
	teams := []float64{}
	for _, p := range st["players"].([]any) {
		teams = append(teams, p.(map[string]any)["team"].(float64))
	}
	if !reflect.DeepEqual(teams, []float64{1, 2, 1, 2}) || st["mode"] != "2v2" {
		t.Fatalf("start inatteso: %v", st)
	}
	// start porta anche le scelte: il client crea la partita con le stesse armi
	pl := st["players"].([]any)
	if pl[0].(map[string]any)["pick"] != w1 || pl[2].(map[string]any)["pick"] != w1 || pl[2].(map[string]any)["secondary"] != s1 {
		t.Fatalf("scelte mancanti nello start: %v", pl)
	}
}

// Chi esce dalla rotellina in partita non torna: gli altri lo sanno subito e
// la partita continua finché restano due squadre
func TestLeave(t *testing.T) {
	url := testServer(t)
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	var c [4]*testClient
	for i := range c {
		c[i] = dial(t, ctx, url)
		c[i].send(`{"t":"hello","v":4,"mode":"ffa"}`)
	}
	you := map[float64]*testClient{}
	for _, x := range c {
		you[x.waitFor(`"start"`)["you"].(float64)] = x
	}
	p1, p2, p3, p4 := you[1], you[2], you[3], you[4]
	p1.send(`{"t":"leave"}`)
	if !p1.closed() {
		t.Fatal("chi esce deve essere disconnesso")
	}
	for _, c := range []*testClient{p2, p3, p4} {
		if m := c.waitFor(`"left"`); m["robot"].(float64) != 1 {
			t.Fatalf("left inatteso: %v", m)
		}
	}
	// tre squadre: si continua, e il robot di chi è uscito è sparito
	for {
		st := p4.waitFor(`"state"`)
		if st["r"].([]any)[0].(map[string]any)["gn"] == true && st["cur"].(float64) != 1 {
			break
		}
	}
	p2.send(`{"t":"leave"}`)
	p3.send(`{"t":"leave"}`)
	// resta una squadra sola: la partita si chiude
	if !p4.closed() {
		t.Fatal("con una squadra sola la partita deve chiudersi")
	}
}

// Coppie di turni e ultimo giro nello stato: av (squadra che ha aperto la
// coppia), ab (i suoi punti allora), fr (ultimo giro, punti doppi) e gd per
// robot (ha già giocato nel giro). Online il tabellone dei punti in attesa e
// dei pallini dei turni li legge da qui.
func TestPairAndFinalRoundInSnapshot(t *testing.T) {
	sim := newTestSim(t, 42, "forgia")
	type stato struct {
		AV int     `json:"av"`
		AB float64 `json:"ab"`
		FR bool    `json:"fr"`
		R  []struct {
			GD bool `json:"gd"`
		} `json:"r"`
	}
	leggi := func() stato {
		var st stato
		if err := json.Unmarshal(sim.Snapshot(), &st); err != nil {
			t.Fatal(err)
		}
		return st
	}
	st := leggi()
	if st.AV != 1 || st.AB != 0 || st.FR || st.R[0].GD || st.R[1].GD {
		t.Fatalf("a inizio partita la coppia è aperta dalla squadra 1, niente ultimo giro: %+v", st)
	}
	// il primo turno finisce da solo allo scadere del tempo
	for i := 0; i < 60*40; i++ {
		if err := sim.Step(Input{}); err != nil {
			t.Fatal(err)
		}
		if leggi().R[0].GD {
			break
		}
	}
	st = leggi()
	if !st.R[0].GD || st.R[1].GD || st.AV != 1 {
		t.Fatalf("dopo il turno del primo: lui ha giocato, la coppia resta sua: %+v", st)
	}
}
