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
	sim, err := e.NewSim(seed, mapID, lua.LNil, nil)
	if err != nil {
		t.Fatal(err)
	}
	return sim
}

// Without a map the seed picks it among the match maps (maps.ROTATION): the
// same seed always gives the same one, and all of them come out.
func TestSimPicksMapFromSeed(t *testing.T) {
	seen := map[string]bool{}
	for seed := int64(1); seed <= 4; seed++ {
		m := newTestSim(t, seed, "").Map()
		if m != newTestSim(t, seed, "").Map() {
			t.Fatalf("seed %d: different map for the same seed", seed)
		}
		seen[m] = true
	}
	if !seen["forgia"] || !seen["crogiolo"] {
		t.Fatalf("maps that came out: %v", seen)
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
		t.Fatalf("snapshot is not valid JSON: %v\n%s", err, sim.Snapshot())
	}
	if st.Phase != "aim" || st.Cur != 1 || len(st.R) != 2 || !st.R[0].G || st.R[0].HP != st.R[0].MH || st.R[0].MH == 0 {
		t.Fatalf("unexpected state: %+v", st)
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
				t.Fatalf("event is not valid JSON: %v\n%s", err, e)
			}
			if ev["type"] == "explosion" || ev["type"] == "miss" {
				found = true
			}
		}
	}
	if !found {
		t.Fatal("the missile never exploded")
	}
}

// On the first turn, after throwing the starting orb, the orbs earned by
// attacking can still be thrown on the server too, and the state carries them
// to the client (te).
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
		t.Fatalf("on the first turn only one starting orb: %d in flight", n)
	}
	var st struct {
		TE int `json:"te"`
	}
	json.Unmarshal(sim.Snapshot(), &st)
	if st.TE != 2 {
		t.Fatalf("attacking at once earns two orbs, state te=%d", st.TE)
	}
	sim.Step(tele)
	sim.Step(tele)
	if n := orbs(); n != 3 {
		t.Fatalf("the two earned orbs must leave: %d in flight", n)
	}
}

// The Rampino hook flies: it's in the state while in flight (gs, gx, gy), so
// online the client draws the rope getting longer; then the "hook" event arrives.
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
		t.Fatalf("the hook doesn't fly (states in flight %d, finished %v)", flying, ended)
	}
}

// Swapping the second attack for a teleport goes through the server like the
// weapons (fire.w = "swap"): one more orb and the attacks closed in the state.
func TestSwapSecondAttack(t *testing.T) {
	sim := newTestSim(t, 42, "forgia")
	type state struct {
		U int `json:"u"`
		R []struct {
			TL int `json:"tl"`
		} `json:"r"`
	}
	read := func() state {
		var st state
		if err := json.Unmarshal(sim.Snapshot(), &st); err != nil {
			t.Fatal(err)
		}
		return st
	}
	for i := 0; i < 20*60; i++ {
		sim.Step(Input{})
	}
	sim.Step(Input{Fire: true, Angle: 1.0, Power: 0.6})
	before := read()
	sim.Step(Input{Fire: true, Weapon: "swap"})
	swapped := false
	for _, e := range sim.Events() {
		var ev map[string]any
		json.Unmarshal(e, &ev)
		if ev["type"] == "swap" {
			swapped = true
		}
	}
	after := read()
	if !swapped || after.R[0].TL != before.R[0].TL+1 || after.U&3 != 3 {
		t.Fatalf("swap failed: event %v, orbs %d -> %d, attacks %d", swapped, before.R[0].TL, after.R[0].TL, after.U)
	}
}

// A reused Lua state must give the same match as a new one: the map copy in
// net.lua must change nothing.
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
		sim, err := e.NewSim(7, "forgia", lua.LNil, nil)
		if err != nil {
			t.Fatal(err)
		}
		if got := play(sim); !sameJSON(got, fresh) {
			t.Fatalf("match %d on the reused state differs:\n%s\n%s", round, got, fresh)
		}
	}
}

// sameJSON compares two messages: key order doesn't matter.
func sameJSON(a, b []byte) bool {
	var x, y any
	return json.Unmarshal(a, &x) == nil && json.Unmarshal(b, &y) == nil && reflect.DeepEqual(x, y)
}

// testClient always reads, like a real client: whoever doesn't read gets
// disconnected by the server when its queue fills up.
type testClient struct {
	t    *testing.T
	conn *websocket.Conn
	ctx  context.Context
	msgs chan []byte // closed when the connection drops
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

// waitFor reads messages until one contains want.
func (c *testClient) waitFor(want string) map[string]any {
	c.t.Helper()
	for data := range c.msgs {
		if strings.Contains(string(data), want) {
			var m map[string]any
			json.Unmarshal(data, &m)
			return m
		}
	}
	c.t.Fatalf("waiting for %q: %v", want, c.err)
	return nil
}

// closed waits for the server to close the connection.
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
	cfg.ReconnectTicks = tickRate / 2 // half a second to come back, so the tests don't take too long
	cfg.DraftTicks = tickRate         // and one second to pick the weapon
	srv := httptest.NewServer(NewServer(cfg).Handler())
	t.Cleanup(srv.Close)
	return "ws" + strings.TrimPrefix(srv.URL, "http") + "/ws"
}

// The players of each queue are those of config.MODES
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
			t.Fatalf("mode %s: %d players, config.MODES[%q] says %v", name, m.Players, m.Sim, v)
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
		t.Fatalf("unexpected answer: %v", m)
	}
	if !c.closed() {
		t.Fatal("the connection should have closed")
	}
}

func TestResumeUnknownToken(t *testing.T) {
	url := testServer(t)
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	c := dial(t, ctx, url)
	c.send(`{"t":"hello","v":8,"tok":"n1.inventato"}`)
	if m := c.waitFor(`"error"`); m["e"] != "expired" || !c.closed() {
		t.Fatalf("unexpected answer: %v", m)
	}
}

func TestOnlineMatch(t *testing.T) {
	url := testServer(t)
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	hello := `{"t":"hello","v":8,"mode":"1v1"}`
	a := dial(t, ctx, url)
	a.send(hello)
	a.waitFor(`"wait"`)
	b := dial(t, ctx, url)
	b.send(hello)

	// First the weapon draft: player 1 takes the first primary and the second
	// secondary of the fans, player 2 doesn't pick and when time's up gets the
	// first free ones
	d := a.waitFor(`"draft"`)
	if len(d["offer"].([]any)) != 3 || len(d["offer2"].([]any)) != 3 || len(d["players"].([]any)) != 2 || d["tok"] == "" {
		t.Fatalf("unexpected draft: %v", d)
	}
	w := d["offer"].([]any)[0].(string)
	w2 := d["offer2"].([]any)[1].(string)
	a.send(`{"t":"pick","w":"` + w + `"}`)
	if d := b.waitFor(`"draft"`); d["you"].(float64) != 2 {
		t.Fatalf("unexpected draft: %v", d)
	}
	if d := a.waitFor(`"draft"`); d["p"] != w {
		t.Fatalf("the pick doesn't come back to whoever made it: %v", d)
	}
	a.send(`{"t":"pick","w":"` + w2 + `"}`)
	if d := a.waitFor(`"draft"`); d["p2"] != w2 {
		t.Fatalf("the secondary doesn't come back to whoever picked it: %v", d)
	}
	sa := a.waitFor(`"start"`)
	sb := b.waitFor(`"start"`)
	if sa["you"].(float64) != 1 || sb["you"].(float64) != 2 || sa["seed"] != sb["seed"] {
		t.Fatalf("unexpected start: %v %v", sa, sb)
	}

	// Player 1 walks: the opponent receives the new position
	first := b.waitFor(`"state"`)
	r0 := first["r"].([]any)[0].(map[string]any)
	x0 := r0["x"].(float64)
	// the state carries crates, shards and shots: player 1 has the shots
	// (config.DRAFT_SHOTS, 2) of the picked primary and their secondary
	r1 := first["r"].([]any)[1].(map[string]any)
	shots := func(r map[string]any) (n float64) {
		for _, k := range []string{"ag", "as", "ap", "ac"} {
			n += r[k].(float64)
		}
		return
	}
	key := map[string]string{"grenade": "ag", "shards": "as", "punch": "ap", "sniper": "ac"}[w]
	if _, ok := first["c"].([]any); !ok || r0[key] != 2.0 || shots(r0) != 2 || shots(r1) != 2 {
		t.Fatalf("state without crates or picked shots: %v", first)
	}
	if r0["ss"] != 2.0 || r1["ss"] != 2.0 {
		t.Fatalf("wrong secondary shots (config.SECONDARY_SHOTS.draft, 2): %v %v", r0["ss"], r1["ss"])
	}
	if r0["sw"] != w2 || r1["sw"] != d["offer2"].([]any)[0].(string) {
		t.Fatalf("wrong picked secondaries: %v %v", r0["sw"], r1["sw"])
	}
	// walking is slow (5 U, 38.8 px/s): one second is enough
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
		t.Fatal("player 1's movement doesn't reach player 2")
	}

	// The teleport orb leaves without ending the turn
	a.send(`{"t":"fire","a":1.7,"p":0.3,"w":"teleport"}`)
	if orb := b.waitFor(`"orb"`); orb["robot"].(float64) != 1 {
		t.Fatalf("orb of the wrong robot: %v", orb)
	}

	// Without shots the Uovo di Fiamma doesn't leave (it stays player 1's turn).
	// Player 2 can't shoot out of turn; player 1 can
	a.send(`{"t":"fire","a":1.0,"p":0.6,"w":"grenade"}`)
	b.send(`{"t":"fire","a":2.0,"p":0.5}`)
	a.send(`{"t":"fire","a":1.0,"p":0.6}`)
	ev := b.waitFor(`"fire"`)
	if ev["robot"].(float64) != 1 {
		t.Fatalf("the wrong robot fired: %v", ev)
	}
	turn := b.waitFor(`"turn"`)
	if turn["robot"].(float64) != 2 {
		t.Fatalf("the turn doesn't pass to player 2: %v", turn)
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

	// Whoever drops can come back with the token: they get the match and the digs again
	a.conn.CloseNow()
	if m := b.waitFor(`"away"`); m["robot"].(float64) != 1 {
		t.Fatalf("unexpected away: %v", m)
	}
	a = dial(t, ctx, url)
	a.send(fmt.Sprintf(`{"t":"hello","v":8,"tok":%q}`, sa["tok"]))
	if m := a.waitFor(`"start"`); m["resume"] != true || m["you"].(float64) != 1 {
		t.Fatalf("unexpected resume: %v", m)
	}
	if m := a.waitFor(`"sync"`); len(m["x"].([]any)) < explosions || explosions == 0 {
		t.Fatalf("missing digs (%d explosions): %v", explosions, m)
	}
	a.waitFor(`"state"`)
	b.waitFor(`"back"`)

	// If they don't come back in time, the other is told and the match ends
	a.conn.CloseNow()
	b.waitFor(`"away"`)
	if m := b.waitFor(`"left"`); m["robot"].(float64) != 1 {
		t.Fatalf("unexpected left: %v", m)
	}
}

// 2 v 2: everyone takes what they want, even the same weapon as their
// teammate, and sees only their own picks (Sergio, 30 Oct); everyone has the Rampino
func TestTeamDraft(t *testing.T) {
	url := testServer(t)
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	var c [4]*testClient
	for i := range c {
		c[i] = dial(t, ctx, url)
		c[i].send(`{"t":"hello","v":8,"mode":"2v2"}`)
	}
	you := map[float64]*testClient{}
	var offer, offer2 []any
	for _, x := range c {
		d := x.waitFor(`"draft"`)
		you[d["you"].(float64)] = x
		offer, offer2 = d["offer"].([]any), d["offer2"].([]any)
		if d["p"] != "" || d["p2"] != "" || d["offer3"] != nil {
			t.Fatalf("unexpected initial draft: %v", d)
		}
	}
	p1, p3 := you[1], you[3]
	w1, s1 := offer[0].(string), offer2[0].(string)
	p1.send(`{"t":"pick","w":"` + w1 + `"}`)
	p3.send(`{"t":"pick","w":"` + w1 + `"}`) // the same as the teammate's: fine
	p3.send(`{"t":"pick","w":"` + s1 + `"}`)
	if d := p1.waitFor(`"draft"`); d["p"] != w1 || d["p2"] != "" {
		t.Fatalf("p1 must see only their own pick: %v", d)
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
		t.Fatalf("unexpected start: %v", st)
	}
	// start also carries the picks: the client creates the match with the same weapons
	pl := st["players"].([]any)
	if pl[0].(map[string]any)["pick"] != w1 || pl[2].(map[string]any)["pick"] != w1 || pl[2].(map[string]any)["secondary"] != s1 {
		t.Fatalf("picks missing in start: %v", pl)
	}
}

// Whoever leaves from the in-match gear wheel doesn't come back: the others
// know at once and the match goes on as long as two teams remain
func TestLeave(t *testing.T) {
	url := testServer(t)
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	var c [4]*testClient
	for i := range c {
		c[i] = dial(t, ctx, url)
		c[i].send(`{"t":"hello","v":8,"mode":"ffa"}`)
	}
	you := map[float64]*testClient{}
	for _, x := range c {
		you[x.waitFor(`"start"`)["you"].(float64)] = x
	}
	p1, p2, p3, p4 := you[1], you[2], you[3], you[4]
	p1.send(`{"t":"leave"}`)
	if !p1.closed() {
		t.Fatal("whoever leaves must be disconnected")
	}
	for _, c := range []*testClient{p2, p3, p4} {
		if m := c.waitFor(`"left"`); m["robot"].(float64) != 1 {
			t.Fatalf("unexpected left: %v", m)
		}
	}
	// three teams: it goes on, and the robot of whoever left is gone
	for {
		st := p4.waitFor(`"state"`)
		if st["r"].([]any)[0].(map[string]any)["gn"] == true && st["cur"].(float64) != 1 {
			break
		}
	}
	p2.send(`{"t":"leave"}`)
	p3.send(`{"t":"leave"}`)
	// only one team left: the match closes
	if !p4.closed() {
		t.Fatal("with only one team the match must close")
	}
}

// Turn pairs and last round in the state: av (team that opened the pair), ab
// (its points then), fr (last round, double points) and gd per robot (has
// already played in the round), gr (the current round: the Crown only exists
// after SCORE.crown_rounds rounds). Online the board of pending points and
// the turn dots read them from here.
func TestPairAndFinalRoundInSnapshot(t *testing.T) {
	sim := newTestSim(t, 42, "forgia")
	type state struct {
		AV int     `json:"av"`
		AB float64 `json:"ab"`
		FR bool    `json:"fr"`
		GR int     `json:"gr"`
		R  []struct {
			GD bool `json:"gd"`
		} `json:"r"`
	}
	read := func() state {
		var st state
		if err := json.Unmarshal(sim.Snapshot(), &st); err != nil {
			t.Fatal(err)
		}
		return st
	}
	st := read()
	if st.AV != 1 || st.AB != 0 || st.FR || st.GR != 1 || st.R[0].GD || st.R[1].GD {
		t.Fatalf("at the start of the match the pair is opened by team 1, no last round: %+v", st)
	}
	// the first turn ends by itself when time runs out
	for i := 0; i < 60*40; i++ {
		if err := sim.Step(Input{}); err != nil {
			t.Fatal(err)
		}
		if read().R[0].GD {
			break
		}
	}
	st = read()
	if !st.R[0].GD || st.R[1].GD || st.AV != 1 {
		t.Fatalf("after the first one's turn: they have played, the pair stays theirs: %+v", st)
	}
	// once the second one's turn is over too round 2 starts
	for i := 0; i < 60*40 && read().GR == 1; i++ {
		if err := sim.Step(Input{}); err != nil {
			t.Fatal(err)
		}
	}
	if st = read(); st.GR != 2 || st.R[0].GD || st.R[1].GD {
		t.Fatalf("after a full round: round 2, nobody has played yet: %+v", st)
	}
}

// Each player's card (level and badges, with the greeting) reaches the others
// with the draft and with start, checked: level between 1 and levelMax, at
// most badgeMax valid badges
func TestShowcases(t *testing.T) {
	url := testServer(t)
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	a := dial(t, ctx, url)
	a.send(`{"t":"hello","v":8,"mode":"1v1","vetrina":{"liv":12,"bdg":[{"id":"mira","grado":2},` +
		`{"id":"<script>","grado":1},{"id":"danno","grado":9},{"id":"globi","grado":4},{"id":"casse","grado":1},{"id":"vinte","grado":1}]}}`)
	a.waitFor(`"wait"`)
	b := dial(t, ctx, url)
	// an empty Lua table arrives as an object: the greeting still counts
	b.send(`{"t":"hello","v":8,"mode":"1v1","vetrina":{"liv":100000,"bdg":{}}}`)
	showcases := func(m map[string]any) string {
		j, _ := json.Marshal(m["vetrine"])
		return string(j)
	}
	want := `[{"bdg":[{"grado":2,"id":"mira"},{"grado":4,"id":"globi"},{"grado":1,"id":"casse"}],"liv":12},{"bdg":[],"liv":999}]`
	if d := b.waitFor(`"draft"`); showcases(d) != want {
		t.Fatalf("cards in the draft: %s, expected %s", showcases(d), want)
	}
	if s := a.waitFor(`"start"`); showcases(s) != want {
		t.Fatalf("cards in start: %s, expected %s", showcases(s), want)
	}
}
