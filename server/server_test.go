package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http/httptest"
	"os/exec"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
	"time"

	"github.com/coder/websocket"
)

// Without a map the seed picks it among the match maps (maps.ROTATION): the
// same seed always gives the same one, and all of them come out.
func TestSimPicksMapFromSeed(t *testing.T) {
	// maps.ROTATION (sim/maps.lua): the first circles' maps are in it too
	rotation := []string{"pavimento", "fossa", "limbo", "lussuria", "gola", "avarizia", "ira", "eresia", "flegetonte", "sabbione", "malebolge", "cocito"}
	seen := map[string]bool{}
	for seed := int64(1); seed <= int64(len(rotation)); seed++ {
		m := newTestSim(t, seed, "").Map()
		if m != newTestSim(t, seed, "").Map() {
			t.Fatalf("seed %d: different map for the same seed", seed)
		}
		seen[m] = true
	}
	for _, id := range rotation {
		if !seen[id] {
			t.Fatalf("maps that came out: %v (missing %s)", seen, id)
		}
	}
}

// The map's hazard goes in the state as it is (hz, sim/hazards.lua): the boulders of
// Avarizia, the level of Ira's water, the phase of Eresia's tombs, the Limbo's lever (upside down or not).
func TestHazardInSnapshot(t *testing.T) {
	for id, field := range map[string]string{"avarizia": `"rocks"`, "ira": `"level"`, "eresia": `"phase"`, "limbo": `"flip"`} {
		sim := newTestSim(t, 7, id)
		sim.Step(Input{})
		if s := string(sim.Snapshot(false, 0)); !strings.Contains(s, `"hz":`) || !strings.Contains(s, field) {
			t.Fatalf("%s: no %s in the state: %s", id, field, s)
		}
	}
}

// The aim of whoever's on turn goes in the state (only while aiming): the
// others see them aim (Sergio, 9 Nov). A bot aims at its best move while it
// thinks, and after THINK_MAX ticks of thinking it moves (net.lua).
func TestAimInSnapshot(t *testing.T) {
	sim := newTestSim(t, 42, "fossa")
	sim.Step(Input{})
	if s := string(sim.Snapshot(true, 1.25)); !strings.Contains(s, `"aim":1.25`) {
		t.Fatalf("no aim in the state: %s", s)
	}
	if s := string(sim.Snapshot(false, 1.25)); strings.Contains(s, `"aim":`) {
		t.Fatalf("aim without aiming: %s", s)
	}
	luaEval(t, `
-- several matches: one lazy turn in a short match is chance, not a bot that stalls
local aimed, turns, lazy = false, 0, 0
for seed = 5, 8 do
local g = N.new(seed, "pavimento", { { team = 1, bot = 5 }, { team = 2, bot = 5 } })
local turn, from, flagged = nil, 0, false
while g.tick < 3000 do
	N.step(g)
	aimed = aimed or N.snapshot(g).aim ~= nil
	if g.turn_no ~= turn then turn, from, flagged = g.turn_no, g.tick, false; turns = turns + 1 end
	local acted = g.used.primary or g.used.secondary or g.used.tool
	-- a bot that stands against the enemy can't always aim at it (random start
	-- points, 9 Nov): a few such turns are fine, most must end in an attack; with the
	-- iron of 26 Nov they walk longer to find a free line, so 15 s before flagging
	if not flagged and not acted and g.phase == "aim" and g.tick - from >= 900 then flagged, lazy = true, lazy + 1 end
end
end
assert(lazy * 4 <= turns, "the bots didn't attack in " .. lazy .. " turns of " .. turns)
assert(aimed, "the bots never showed their aim")
`, nil)
}

func TestSimFromEmbeddedLua(t *testing.T) {
	sim := newTestSim(t, 42, "fossa")
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
	if err := json.Unmarshal(sim.Snapshot(false, 0), &st); err != nil {
		t.Fatalf("snapshot is not valid JSON: %v\n%s", err, sim.Snapshot(false, 0))
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

// On the first turn every orb can be thrown on the server too: both starting
// orbs and then the two earned by attacking at once (Sergio, 3 November).
func TestEarnedTeleportsFirstTurn(t *testing.T) {
	sim := newTestSim(t, 42, "pavimento")
	orbs := func() int {
		var st struct {
			O []json.RawMessage `json:"o"`
		}
		if err := json.Unmarshal(sim.Snapshot(false, 0), &st); err != nil {
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
	if n := orbs(); n != 2 {
		t.Fatalf("on the first turn both starting orbs leave: %d in flight", n)
	}
	sim.Step(tele)
	sim.Step(tele)
	if n := orbs(); n != 4 {
		t.Fatalf("the two earned orbs must leave too: %d in flight", n)
	}
}

// The Rampino hook flies: it's in the state while in flight (gs, gx, gy), so
// online the client draws the rope getting longer; then the "hook" event arrives.
func TestHookShotInSnapshot(t *testing.T) {
	sim := newTestSim(t, 42, "pavimento")
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
		if err := json.Unmarshal(sim.Snapshot(false, 0), &st); err != nil {
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
	sim := newTestSim(t, 42, "pavimento")
	type state struct {
		U int `json:"u"`
		R []struct {
			TL int `json:"tl"`
		} `json:"r"`
	}
	read := func() state {
		var st state
		if err := json.Unmarshal(sim.Snapshot(false, 0), &st); err != nil {
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

// A process that has already played must give the same match as a new one:
// the copy of the drawn map in net.lua must change nothing.
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
		return sim.Snapshot(false, 0)
	}
	fresh := play(newTestSimOn(t, testProc(t), 7, "pavimento"))
	p := testProc(t)
	for round := 0; round < 3; round++ {
		sim := newTestSimOn(t, p, 7, "pavimento")
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
	t     *testing.T
	conn  *websocket.Conn
	ctx   context.Context
	msgs  chan []byte // closed when the connection drops
	err   error
	next  int            // the next tick of the match, from the "k" read so far
	cur   int            // the robot on turn then
	state map[string]any // the last state read
}

// keys reads a "k" message (the keys of the ticks played) if data is one
func (c *testClient) keys(data []byte) {
	var m struct {
		T      string
		N      int
		K      []string
		Cur    int
		Resume bool
	}
	if json.Unmarshal(data, &m) != nil {
		return
	}
	if m.T == "state" {
		json.Unmarshal(data, &c.state)
	} else if m.T == "k" {
		c.next, c.cur = m.N+len(m.K), m.Cur
	} else if m.T == "start" && !m.Resume {
		c.next, c.cur = 0, m.Cur
	}
}

// drain reads what has already arrived, until nothing comes for a while: on
// our turn the match waits for our keys
func (c *testClient) drain() {
	c.t.Helper()
	for {
		select {
		case data, ok := <-c.msgs:
			if !ok {
				c.t.Fatalf("leading: %v", c.err)
			}
			c.keys(data)
		case <-time.After(100 * time.Millisecond):
			return
		}
	}
}

// lead plays the codes (sim/netkeys.lua) as the phone of robot you does: on
// its turn, from the next tick
func (c *testClient) lead(you int, codes ...string) {
	c.t.Helper()
	for c.drain(); c.cur != you; c.drain() {
	}
	// a hundred at a time (the server reads small messages)
	for len(codes) > 0 {
		n := min(len(codes), 100)
		k, _ := json.Marshal(codes[:n])
		c.send(fmt.Sprintf(`{"t":"k","n":%d,"k":%s}`, c.next, k))
		c.next += n
		codes = codes[n:]
	}
}

// play: lead the codes, then nothing until the turn passes
func (c *testClient) play(you int, codes ...string) {
	c.t.Helper()
	c.lead(you, codes...)
	for c.drain(); c.cur == you; c.drain() {
		c.lead(you, still(60)...)
	}
}

// still: n ticks of no keys
func still(n int, codes ...string) []string {
	for i := 0; i < n; i++ {
		codes = append(codes, "")
	}
	return codes
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
		c.keys(data)
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

func testServer(t *testing.T, change ...func(*Config)) string {
	cfg := DefaultConfig()
	cfg.ReconnectTicks = tickRate / 2 // half a second to come back, so the tests don't take too long
	cfg.DraftTicks = tickRate         // and one second to pick the weapon
	for _, c := range change {
		c(&cfg)
	}
	srv := httptest.NewServer(NewServer(cfg).Handler())
	t.Cleanup(srv.Close)
	return "ws" + strings.TrimPrefix(srv.URL, "http") + "/ws"
}

// The players of each queue are those of config.MODES
func TestModesMatchConfig(t *testing.T) {
	for name, m := range modes {
		var list []struct {
			Team int `json:"team"`
		}
		luaEval(t, fmt.Sprintf("return N.mode_players(%q)", m.Sim), &list)
		if len(list) != m.Players {
			t.Fatalf("mode %s: %d players, config.MODES[%q] says %v", name, m.Players, m.Sim, list)
		}
		// and the teams of the rooms (room.go and private.go, modeTeam)
		for i, p := range list {
			if p.Team != modeTeam(m.Sim, i) {
				t.Fatalf("mode %s seat %d: team %d in config.MODES, %d in modeTeam", name, i+1, p.Team, modeTeam(m.Sim, i))
			}
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

// A phone with another simulation is told to update (simtree.go); with the
// server's own, or none (the simulator), it gets in
func TestHelloOtherSimulation(t *testing.T) {
	url := testServer(t)
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	c := dial(t, ctx, url)
	c.send(fmt.Sprintf(`{"t":"hello","v":%d,"mode":"1v1","sim":"0123456789abcdef"}`, protocolVersion))
	if m := c.waitFor(`"error"`); m["e"] != "sim" {
		t.Fatalf("unexpected answer: %v", m)
	}
	if !c.closed() {
		t.Fatal("the connection should have closed")
	}
	ok := dial(t, ctx, url)
	ok.send(fmt.Sprintf(`{"t":"hello","v":%d,"mode":"1v1","sim":%q}`, protocolVersion, simTree))
	if m := ok.waitFor(`"wait"`); m["t"] != "wait" {
		t.Fatalf("unexpected answer: %v", m)
	}
}

// The fingerprint is the one git gives the folder (what apk.yml puts in the
// APK), when client/sim has nothing left to commit
func TestSimTreeIsGit(t *testing.T) {
	if exec.Command("git", "diff", "--quiet", "HEAD", "--", "../client/sim").Run() != nil {
		t.Skip("client/sim ha modifiche non salvate, o manca git")
	}
	out, err := exec.Command("git", "rev-parse", "HEAD:client/sim").Output()
	if err != nil {
		t.Skip("git non risponde: ", err)
	}
	if got := strings.TrimSpace(string(out)); got != simTree {
		t.Fatalf("git dice %s, il server %s", got, simTree)
	}
}

func TestResumeUnknownToken(t *testing.T) {
	url := testServer(t)
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	c := dial(t, ctx, url)
	c.send(`{"t":"hello","v":11,"tok":"n1.inventato"}`)
	if m := c.waitFor(`"error"`); m["e"] != "expired" || !c.closed() {
		t.Fatalf("unexpected answer: %v", m)
	}
}

func TestOnlineMatch(t *testing.T) {
	url := testServer(t)
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	hello := `{"t":"hello","v":11,"mode":"1v1"}`
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
	// the draft already says the match's map (the lineup shows what drops there)
	if d["map"] == nil || d["map"] != sa["map"] {
		t.Fatalf("the draft's map %v is not the match's %v", d["map"], sa["map"])
	}

	// The match waits for the phone of whoever is on turn (robot 1, during the
	// 3-2-1 too: 3 s, game.INTRO_TICKS), which plays at once and sends its keys:
	// the opponent gets them and the state every half second (the check)
	a.lead(1, still(180)...)
	first := b.waitFor(`"state"`)
	if first["n"].(float64) != stateEvery || first["fp"] == nil {
		t.Fatalf("state without tick or fingerprint: %v", first)
	}
	r0 := first["r"].([]any)[0].(map[string]any)
	x0 := r0["x"].(float64)
	// the state carries crates, shards and shots: player 1 has the shots
	// (config.DRAFT_SHOTS, 2) of the picked primary and their secondary
	r1 := first["r"].([]any)[1].(map[string]any)
	shots := func(r map[string]any) (n float64) {
		for _, k := range []string{"ag", "as", "ap", "ac", "ab", "at", "ar"} {
			n += r[k].(float64)
		}
		return
	}
	key := map[string]string{"grenade": "ag", "shards": "as", "punch": "ap", "sniper": "ac", "boomerang": "ab", "tar": "at", "drill": "ar"}[w]
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
	walk := make([]string, 60)
	for i := range walk {
		walk[i] = "r"
	}
	a.lead(1, still(300, walk...)...)
	moved := false
	for i := 0; i < 60 && !moved; i++ {
		st := b.waitFor(`"state"`)
		x := st["r"].([]any)[0].(map[string]any)["x"].(float64)
		moved = x > x0+10
	}
	if !moved {
		t.Fatal("player 1's movement doesn't reach player 2")
	}
	// the keys come back to everyone as the server applied them
	if b.cur != 1 || b.next <= 180 {
		t.Fatalf("keys of the ticks played don't reach player 2: robot %d, tick %d", b.cur, b.next)
	}

	// The teleport orb leaves without ending the turn
	a.lead(1, still(300, "fteleport,1.7,0.3")...)
	for st := b.waitFor(`"state"`); ; st = b.waitFor(`"state"`) {
		if st["cur"].(float64) != 1 {
			t.Fatalf("the teleport ended the turn: %v", st)
		}
		if st["r"].([]any)[0].(map[string]any)["tl"].(float64) < r0["tl"].(float64) {
			break
		}
	}

	// Without shots the Uovo di Fiamma doesn't leave (it stays player 1's turn).
	// Player 2's keys out of turn count for nothing; player 1 fires
	b.send(fmt.Sprintf(`{"t":"k","n":%d,"k":["fmissile,2,0.5"]}`, b.next))
	a.play(1, "fgrenade,1,0.6", "", "fmissile,1,0.6")
	if b.drain(); b.cur != 2 || shots(b.state["r"].([]any)[1].(map[string]any)) != 2 {
		t.Fatalf("player 2 fired out of turn, or the turn didn't pass: robot %d, %v", b.cur, b.state)
	}

	// Player 2's shot passes the turn back
	b.play(2, "fmissile,2.2,0.7")
	if a.drain(); a.cur != 1 {
		t.Fatalf("the turn doesn't come back to player 1: robot %d", a.cur)
	}
	played := a.next

	// Whoever drops can come back with the token: they get the match again,
	// all the keys from the start (the phone replays them)
	a.conn.CloseNow()
	if m := b.waitFor(`"away"`); m["robot"].(float64) != 1 {
		t.Fatalf("unexpected away: %v", m)
	}
	a = dial(t, ctx, url)
	a.send(fmt.Sprintf(`{"t":"hello","v":11,"tok":%q}`, sa["tok"]))
	if m := a.waitFor(`"start"`); m["resume"] != true || m["you"].(float64) != 1 {
		t.Fatalf("unexpected resume: %v", m)
	}
	if m := a.waitFor(`"t":"k"`); m["n"].(float64) != 0 {
		t.Fatalf("the keys don't start from the beginning: n %v", m["n"])
	}
	if a.drain(); a.next < played {
		t.Fatalf("missing keys: %d ticks played, %d come back", played, a.next)
	}
	b.waitFor(`"back"`)

	// (who never comes back keeps the seat and a bot plays their turns: TestStandIn)
}

// Whoever drops in a match is replaced by a bot until they come back (Sergio,
// 17 Nov: "non sono più riuscito né a rientrare e né si è riempito il mio
// posto con un bot"): the bot plays their turn, the seat stays theirs and
// coming back they get the match again.
func TestStandIn(t *testing.T) {
	url := testServer(t, func(c *Config) {
		c.StandInTicks = tickRate / 2
	})
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	hello := `{"t":"hello","v":11,"mode":"1v1"}`
	a := dial(t, ctx, url)
	a.send(hello)
	a.waitFor(`"wait"`)
	b := dial(t, ctx, url)
	b.send(hello)
	sa := a.waitFor(`"start"`)
	b.waitFor(`"start"`)
	a.conn.CloseNow()
	if m := b.waitFor(`"away"`); m["robot"].(float64) != 1 {
		t.Fatalf("unexpected away: %v", m)
	}
	// robot 1's turn goes on without its player: the bot shoots (a code with
	// a shot that isn't a teleport, in the keys the server sends) well before
	// the turn's time is up
	began := time.Now()
	for shot := false; !shot; {
		data, ok := <-b.msgs
		if !ok {
			t.Fatalf("waiting for the stand-in's shot: %v", b.err)
		}
		var m struct {
			T   string
			K   []string
			Cur int
		}
		json.Unmarshal(data, &m)
		if m.T != "k" {
			continue
		}
		for _, c := range m.K {
			shot = shot || strings.Contains(c, "f") && !strings.Contains(c, "fteleport")
		}
		if !shot && m.Cur != 1 {
			t.Fatalf("robot 1's turn passed without an attack")
		}
	}
	if d := time.Since(began); d > 15*time.Second {
		t.Fatalf("the stand-in took %v to attack", d)
	}
	// back with the token in the middle of the turn: the seat is still theirs,
	// the bot finishes the turn (si in the state) and the next one is theirs
	a = dial(t, ctx, url)
	a.send(fmt.Sprintf(`{"t":"hello","v":11,"tok":%q}`, sa["tok"]))
	if m := a.waitFor(`"start"`); m["resume"] != true || m["you"].(float64) != 1 {
		t.Fatalf("unexpected resume: %v", m)
	}
	b.waitFor(`"back"`)
	if st := a.waitFor(`"t":"state"`); st["cur"].(float64) != 1 || st["si"] != true {
		t.Fatalf("the bot should be finishing robot 1's turn: cur %v si %v", st["cur"], st["si"])
	}
	// player 2 passes their turn by shooting; then robot 1 is its player's again
	b.play(2, "fmissile,2.2,0.7")
	for st := a.waitFor(`"t":"state"`); st["cur"].(float64) != 2; st = a.waitFor(`"t":"state"`) {
	}
	a.lead(1, still(120)...)
	for {
		st := a.waitFor(`"t":"state"`)
		if st["cur"].(float64) == 1 && st["phase"] == "aim" {
			if st["si"] != nil {
				t.Fatalf("robot 1 is back but the bot still plays: %v", st["si"])
			}
			break
		}
	}
	// and whoever never comes back keeps the seat: nobody is told they left
	a.conn.CloseNow()
	b.waitFor(`"away"`)
	deadline := time.After(2 * time.Second)
	for more := true; more; {
		select {
		case data := <-b.msgs:
			if strings.Contains(string(data), `"left"`) {
				t.Fatalf("the seat was not kept: %s", data)
			}
		case <-deadline:
			more = false
		}
	}
}

// PRONTO (Sergio, 16 Nov): it counts only with both weapons picked, the others
// see it, a different pick takes it away, and when everyone is ready the
// match starts without waiting for the draft's time (here a minute)
func TestDraftReady(t *testing.T) {
	url := testServer(t, func(c *Config) { c.DraftTicks = 60 * tickRate })
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	hello := `{"t":"hello","v":11,"mode":"1v1"}`
	a := dial(t, ctx, url)
	a.send(hello)
	a.waitFor(`"wait"`)
	b := dial(t, ctx, url)
	b.send(hello)
	d := a.waitFor(`"draft"`)
	offer, offer2 := d["offer"].([]any), d["offer2"].([]any)
	pick := func(c *testClient, w any) { c.send(`{"t":"pick","w":"` + w.(string) + `"}`) }
	// until the draft says so: rd is who is ready, robot by robot
	until := func(c *testClient, rd ...float64) {
		t.Helper()
		for {
			d := c.waitFor(`"draft"`)
			got := d["rd"].([]any)
			if got[0] == rd[0] && got[1] == rd[1] {
				return
			}
		}
	}
	a.send(`{"t":"ready"}`) // nothing picked: it doesn't count
	pick(a, offer[0])
	pick(a, offer2[0])
	a.send(`{"t":"ready"}`)
	until(b, 1, 0) // the other one sees it
	until(a, 1, 0)
	pick(a, offer[1]) // a different pick: no longer ready
	until(b, 0, 0)
	a.send(`{"t":"ready"}`)
	until(b, 1, 0)
	pick(b, offer[0])
	pick(b, offer2[1])
	b.send(`{"t":"ready"}`)
	st := b.waitFor(`"start"`)
	p := st["players"].([]any)[0].(map[string]any)
	if p["pick"] != offer[1] || p["secondary"] != offer2[0] {
		t.Fatalf("the match must start with the picks made: %v", st)
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
		c[i].send(`{"t":"hello","v":11,"mode":"2v2"}`)
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
		c[i].send(`{"t":"hello","v":11,"mode":"ffa"}`)
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
	sim := newTestSim(t, 42, "pavimento")
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
		if err := json.Unmarshal(sim.Snapshot(false, 0), &st); err != nil {
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

// Each player's card (level, badges, pieces worn) comes from their profile on
// the server (accounts.go Cards), never from what the phone says, and reaches
// the others with the draft and with start; without a profile the base card.
func TestShowcases(t *testing.T) {
	url, acc := testServerProfiles(t)
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	a := dial(t, ctx, url)
	a.send(`{"t":"hello","v":11,"mode":"1v1","profilo":"` + guest(t, acc, `p.livello = 12
		p.posseduti.corvo_mask, p.pezzi.corvo_mask = true, 24
		p.loadouts[1].gear.mask = "corvo"`) + `","vetrina":{"liv":99}}`)
	a.waitFor(`"wait"`)
	b := dial(t, ctx, url)
	b.send(`{"t":"hello","v":11,"mode":"1v1","profilo":"1.sbagliata"}`)
	showcases := func(m map[string]any) string {
		j, _ := json.Marshal(m["vetrine"])
		return string(j)
	}
	want := `[{"bdg":[],"liv":12,"pz":[{"liv":20,"set":"corvo"},{"liv":0,"set":""},{"liv":0,"set":""},{"liv":0,"set":""},{"liv":0,"set":""}]},{}]`
	if d := b.waitFor(`"draft"`); showcases(d) != want {
		t.Fatalf("cards in the draft: %s, expected %s", showcases(d), want)
	}
	if s := a.waitFor(`"start"`); showcases(s) != want {
		t.Fatalf("cards in start: %s, expected %s", showcases(s), want)
	}
}

// testServerProfiles: a test server with the guest profiles (accounts.go)
func testServerProfiles(t *testing.T, change ...func(*Config)) (string, *Accounts) {
	t.Helper()
	acc, err := OpenAccounts(filepath.Join(t.TempDir(), "megablast.db"))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { acc.Close() })
	cfg := DefaultConfig()
	cfg.ReconnectTicks = tickRate / 2
	cfg.DraftTicks = tickRate
	for _, c := range change {
		c(&cfg)
	}
	s := NewServer(cfg)
	s.accounts = acc
	srv := httptest.NewServer(s.Handler())
	t.Cleanup(srv.Close)
	return "ws" + strings.TrimPrefix(srv.URL, "http") + "/ws", acc
}

// guest: a profile born from the phone's progress (lua changes p, a new
// profile), as the greeting carries it: "<id>.<chiave>"
func guest(t *testing.T, acc *Accounts, lua string) string {
	t.Helper()
	var text string
	luaEval(t, `local p = require("sim.profile").new()
		`+lua+`
		return require("sim.replay").write(p)`, &text)
	a, _, err := acc.New(text)
	if err != nil {
		t.Fatal(err)
	}
	return itoa(a.ID) + "." + a.Key
}

// The waiting room (client/menu/lobby.lua): everyone in the queue gets the
// cards of who is waiting, at every join and leave, with their own place.
func TestWaitingRoom(t *testing.T) {
	url, acc := testServerProfiles(t)
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	a := dial(t, ctx, url)
	a.send(`{"t":"hello","v":11,"mode":"2v2","profilo":"` + guest(t, acc, "p.livello = 3") + `"}`)
	w := a.waitFor(`"wait"`)
	if w["of"] != float64(4) || w["you"] != float64(1) || len(w["vetrine"].([]any)) != 1 {
		t.Fatalf("first wait: %v", w)
	}
	b := dial(t, ctx, url)
	b.send(`{"t":"hello","v":11,"mode":"2v2","profilo":"` + guest(t, acc, "p.livello = 5") + `"}`)
	w = b.waitFor(`"wait"`)
	cards := w["vetrine"].([]any)
	if w["you"] != float64(2) || len(cards) != 2 || cards[0].(map[string]any)["liv"] != float64(3) {
		t.Fatalf("second wait: %v", w)
	}
	if w = a.waitFor(`"wait"`); len(w["vetrine"].([]any)) != 2 {
		t.Fatalf("the first doesn't see the second: %v", w)
	}
	// the first leaves: the second moves up to place 1
	a.conn.Close(websocket.StatusNormalClosure, "")
	w = b.waitFor(`"wait"`)
	if w["you"] != float64(1) || len(w["vetrine"].([]any)) != 1 {
		t.Fatalf("after leaving: %v", w)
	}
}

// "leave" while queued takes you out at once (ESCI DALLA CODA, another
// queue): the one behind moves up to first place, with the bots' clock
// from when they joined, and the server closes the connection.
func TestLeaveQueue(t *testing.T) {
	url := testServer(t)
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	a := dial(t, ctx, url)
	a.send(`{"t":"hello","v":11,"mode":"2v2"}`)
	a.waitFor(`"wait"`)
	b := dial(t, ctx, url)
	b.send(`{"t":"hello","v":11,"mode":"2v2"}`)
	b.waitFor(`"you":2`)
	a.send(`{"t":"leave"}`)
	if w := b.waitFor(`"wait"`); w["you"] != float64(1) || len(w["vetrine"].([]any)) != 1 {
		t.Fatalf("after leave: %v", w)
	}
	if !a.closed() {
		t.Fatal("the server didn't close the connection of who left the queue")
	}
}

// Bots fill the queue (lobby.go): two people in a 2 vs 2, after BotAfter
// (here one second) the match starts with two bots, and the people are on
// different teams. Each bot wears as much as the person of the other team
// (sim/loadout.lua dress_bots): A's level against A, nothing against B, who
// has no profile; the draft and start say it, and the life shows it.
func TestBotsFillQueue(t *testing.T) {
	url, acc := testServerProfiles(t, func(c *Config) { c.BotAfter = time.Second })
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	a := dial(t, ctx, url)
	a.send(`{"t":"hello","v":11,"mode":"2v2","profilo":"` + guest(t, acc, "p.livello = 12") + `"}`)
	if w := a.waitFor(`"wait"`); w["bot_in"] == nil {
		t.Fatalf("no bot_in in a normal queue: %v", w)
	}
	b := dial(t, ctx, url)
	b.send(`{"t":"hello","v":11,"mode":"2v2"}`)
	d := a.waitFor(`"draft"`)
	players := d["players"].([]any)
	cards := d["vetrine"].([]any)
	if len(players) != 4 || players[0].(map[string]any)["team"] == players[1].(map[string]any)["team"] {
		t.Fatalf("the two people must be on different teams: %v", players)
	}
	for i := 2; i < 4; i++ {
		if players[i].(map[string]any)["bot"] != float64(4) || cards[i].(map[string]any)["bot"] != true {
			t.Fatalf("seat %d is not a grade 4 bot (average level 6): %v %v", i+1, players, cards)
		}
	}
	botEq := func(players []any) (any, any) {
		return players[2].(map[string]any)["eq"], players[3].(map[string]any)["eq"]
	}
	if mate, rival := botEq(players); mate != nil || rival == nil || rival.(map[string]any)["liv"] != float64(12) {
		t.Fatalf("the bots' eq in the draft: %v", players)
	}
	b.waitFor(`"draft"`)
	if mate, rival := botEq(a.waitFor(`"start"`)["players"].([]any)); mate != nil || rival.(map[string]any)["liv"] != float64(12) {
		t.Fatalf("the bots' eq in start: %v %v", mate, rival)
	}
	// a few game states arrive: the room with bots runs (that they play is
	// checked by TestNetBotPlays, without waiting for the real turns)
	a.waitFor(`"t":"state"`)
	a.waitFor(`"t":"state"`)
}

// A test profile (FINE GIOCO, DA ZERO: no "profilo") sends what it wears with
// the greeting ("prova", Sergio 22 Nov): it counts online, so its bot wears as
// much; the plain "eq" of an old phone still counts for nothing.
func TestTestProfileEquip(t *testing.T) {
	url := testServer(t, func(c *Config) { c.BotAfter = time.Second })
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	a := dial(t, ctx, url)
	a.send(`{"t":"hello","v":11,"mode":"1v1","prova":{"liv":30,"gear":{"mask":"corvo"},"lv":{"mask":20},"tree":{"armor":15}}}`)
	players := a.waitFor(`"start"`)["players"].([]any)
	me, bot := players[0].(map[string]any)["eq"], players[1].(map[string]any)["eq"]
	if me == nil || bot == nil || bot.(map[string]any)["liv"] != float64(30) || bot.(map[string]any)["gear"] == nil {
		t.Fatalf("the test profile's eq and its bot's: %v %v", me, bot)
	}
}

// A bot seat in net.lua (N.new with players[i].bot) plays its turn by itself
// on the server: it shoots and passes the turn on, with the server's work
// budget, the same as on the phone.
func TestNetBotPlays(t *testing.T) {
	luaEval(t, `
local g = N.new(5, nil, { { team = 1, bot = 4 }, { team = 2, bot = 4 } })
local shot = false
while g.tick < 3000 and N.current(g) == 1 do
	N.step(g)
	shot = shot or g.used.primary or g.used.secondary
end
assert(shot, "the bot didn't shoot")
assert(N.current(g) ~= 1, "the bot's turn didn't end")
`, nil)
}

// Private room (private.go): A opens it, B joins with the code and lands in
// the first bot seat (the other team), moves to A's team; A sets the grade of
// a bot and starts: the draft has the people and the bots where they sat.
func TestPrivateRoom(t *testing.T) {
	url := testServer(t)
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	a := dial(t, ctx, url)
	a.send(`{"t":"hello","v":11,"privata":"nuova"}`)
	m := a.waitFor(`"privata"`)
	code, _ := m["code"].(string)
	if len(code) != 4 || m["mode"] != "2v2" || m["you"] != float64(1) || m["host"] != float64(1) || len(m["posti"].([]any)) != 4 {
		t.Fatalf("new room: %v", m)
	}
	// a wrong code: error and closed
	x := dial(t, ctx, url)
	x.send(`{"t":"hello","v":11,"privata":"x"}`)
	if e := x.waitFor(`"error"`); e["e"] != "codice" || !x.closed() {
		t.Fatalf("wrong code: %v", e)
	}
	b := dial(t, ctx, url)
	b.send(`{"t":"hello","v":11,"privata":"` + code + `"}`)
	if m = b.waitFor(`"privata"`); m["you"] != float64(2) {
		t.Fatalf("B must take seat 2: %v", m)
	}
	b.send(`{"t":"posto","i":3}`) // with A, team 1
	b.waitFor(`"you":3`)
	b.send(`{"t":"bot","i":2,"g":9}`) // not the host: nothing
	a.send(`{"t":"bot","i":4,"g":9}`)
	m = a.waitFor(`{"team":2,"bot":9}]`)
	if p := m["posti"].([]any); p[1].(map[string]any)["bot"] != float64(3) {
		t.Fatalf("seat 2 must stay a grade 3 bot: %v", p)
	}
	a.send(`{"t":"via"}`)
	d := b.waitFor(`"draft"`)
	players := d["players"].([]any)
	want := []string{`{"team":1}`, `{"bot":3,"team":2}`, `{"team":1}`, `{"bot":9,"team":2}`}
	for i, p := range players {
		got, _ := json.Marshal(p)
		if string(got) != want[i] {
			t.Fatalf("seat %d: %s, want %s", i+1, got, want[i])
		}
	}
	a.waitFor(`"draft"`)
	a.waitFor(`"start"`)
	b.waitFor(`"t":"state"`)
}

// The host changes mode (the people go first) and leaves: the next person
// becomes host, their seat a bot; with nobody left the code no longer works.
func TestPrivateRoomModeAndLeave(t *testing.T) {
	url := testServer(t)
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	a := dial(t, ctx, url)
	a.send(`{"t":"hello","v":11,"privata":"nuova"}`)
	code := a.waitFor(`"privata"`)["code"].(string)
	b := dial(t, ctx, url)
	b.send(`{"t":"hello","v":11,"privata":"` + code + `"}`)
	b.waitFor(`"privata"`)
	a.send(`{"t":"modo","mode":"1v1"}`)
	if m := b.waitFor(`"1v1"`); len(m["posti"].([]any)) != 2 || m["you"] != float64(2) {
		t.Fatalf("1 vs 1: %v", m)
	}
	// full of people: a third can't come in
	c := dial(t, ctx, url)
	c.send(`{"t":"hello","v":11,"privata":"` + code + `"}`)
	if e := c.waitFor(`"error"`); e["e"] != "piena" {
		t.Fatalf("full room: %v", e)
	}
	a.send(`{"t":"leave"}`)
	if m := b.waitFor(`"host":2`); m["posti"].([]any)[0].(map[string]any)["bot"] == nil {
		t.Fatalf("A's seat must be a bot: %v", m)
	}
	b.send(`{"t":"leave"}`)
	b.closed()
	d := dial(t, ctx, url)
	d.send(`{"t":"hello","v":11,"privata":"` + code + `"}`)
	if e := d.waitFor(`"error"`); e["e"] != "codice" {
		t.Fatalf("the empty room must be gone: %v", e)
	}
}

// The private room outlives its match (Sergio, 22 Nov): while it plays its
// code is busy; when it closes (here B leaves, one team is left) A is back in
// the same room on the same connection, on the podium: VIA waits for "torna",
// then a new match starts. B's seat is a bot.
func TestPrivateRoomAfterMatch(t *testing.T) {
	url := testServer(t)
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	a := dial(t, ctx, url)
	a.send(`{"t":"hello","v":11,"privata":"nuova"}`)
	code := a.waitFor(`"privata"`)["code"].(string)
	b := dial(t, ctx, url)
	b.send(`{"t":"hello","v":11,"privata":"` + code + `"}`)
	b.waitFor(`"privata"`)
	a.send(`{"t":"modo","mode":"1v1"}`)
	b.waitFor(`"1v1"`)
	a.send(`{"t":"via"}`)
	a.waitFor(`"start"`)
	b.waitFor(`"start"`)
	c := dial(t, ctx, url)
	c.send(`{"t":"hello","v":11,"privata":"` + code + `"}`)
	if e := c.waitFor(`"error"`); e["e"] != "partita" {
		t.Fatalf("a room in a match: %v", e)
	}
	b.send(`{"t":"leave"}`)
	m := a.waitFor(`"privata"`)
	seats := m["posti"].([]any)
	if m["code"] != code || m["mode"] != "1v1" || m["host"] != float64(1) || len(seats) != 2 ||
		seats[0].(map[string]any)["podio"] != true || seats[1].(map[string]any)["bot"] == nil {
		t.Fatalf("back in the room: %v", m)
	}
	a.send(`{"t":"via"}`) // still on the podium: nothing
	if m = a.waitFor(`"privata"`); m["posti"].([]any)[0].(map[string]any)["podio"] != true {
		t.Fatalf("VIA from the podium: %v", m)
	}
	a.send(`{"t":"torna"}`)
	if m = a.waitFor(`"privata"`); m["posti"].([]any)[0].(map[string]any)["podio"] != nil {
		t.Fatalf("after torna: %v", m)
	}
	a.send(`{"t":"via"}`)
	if d := a.waitFor(`"draft"`); len(d["players"].([]any)) != 2 {
		t.Fatalf("second match: %v", d)
	}
}

// The rate limit (server.go): a burst gets through, a flood doesn't, and the
// tokens come back with time.
func TestRateLimit(t *testing.T) {
	var l rateLimit
	now := time.Unix(1000, 0)
	ok := 0
	for i := 0; i < 200; i++ {
		if l.allow(now) {
			ok++
		}
	}
	if ok != msgBurst {
		t.Fatalf("burst: %d messages through, want %d", ok, msgBurst)
	}
	now = now.Add(time.Second)
	ok = 0
	for i := 0; i < 200; i++ {
		if l.allow(now) {
			ok++
		}
	}
	if ok != msgRate {
		t.Fatalf("after a second: %d messages through, want %d", ok, msgRate)
	}
}

// What a player wears (Sigilli, pieces with levels and signatures, level)
// comes from their profile on the server and makes the stats of their robot
// in the match, and reaches everyone with start; whoever has no profile plays
// with the base stats, whatever the phone says.
func TestEquipStats(t *testing.T) {
	url, acc := testServerProfiles(t)
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	a := dial(t, ctx, url)
	a.send(`{"t":"hello","v":11,"mode":"1v1","profilo":"` + guest(t, acc, `p.livello = 30
		p.posseduti.corvo_mask, p.pezzi.corvo_mask, p.firme.corvo_mask = true, 20, 3
		p.posseduti.corvo_chest, p.pezzi.corvo_chest = true, 12
		p.loadouts[1].gear = { mask = "corvo", chest = "corvo" }
		p.loadouts[1].tree = { armor = 15, pick = { armor = { 1, nil, 2 } } }`) + `"}`)
	a.waitFor(`"wait"`)
	b := dial(t, ctx, url)
	b.send(`{"t":"hello","v":11,"mode":"1v1","eq":{"liv":30,"tree":{"armor":15}}}`)
	s := a.waitFor(`"start"`)
	players, _ := json.Marshal(s["players"])
	var ps []struct {
		Eq map[string]any `json:"eq"`
	}
	if err := json.Unmarshal(players, &ps); err != nil || len(ps) != 2 {
		t.Fatalf("players in start: %s", players)
	}
	if ps[0].Eq == nil || ps[1].Eq != nil {
		t.Fatalf("eq in start: %s", players)
	}
	// the signature of a piece at level 20 is lit two grades at most
	if sg := ps[0].Eq["sg"].(map[string]any); sg["mask"] != 2.0 {
		t.Fatalf("signatures: %v", sg)
	}
	st := a.waitFor(`"state"`)
	robots := st["r"].([]any)
	hp1, hp2 := robots[0].(map[string]any)["hp"].(float64), robots[1].(map[string]any)["hp"].(float64)
	if hp1 <= 100 || hp2 != 100 {
		t.Fatalf("life at the start: %v and %v, expected more than 100 and 100", hp1, hp2)
	}
}

// With every player away for longer than EmptyTicks the room closes (Sergio,
// 18 Nov): the stand-in bots don't play the match to the end for nobody.
// One player away keeps the room, and their seat.
func TestEmptyRoomCloses(t *testing.T) {
	url := testServer(t, func(c *Config) {
		c.EmptyTicks = tickRate / 2
	})
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	hello := `{"t":"hello","v":11,"mode":"1v1"}`
	a := dial(t, ctx, url)
	a.send(hello)
	a.waitFor(`"wait"`)
	b := dial(t, ctx, url)
	b.send(hello)
	sa := a.waitFor(`"start"`)
	b.waitFor(`"start"`)
	back := fmt.Sprintf(`{"t":"hello","v":11,"tok":%q}`, sa["tok"])
	// only one away, well past the time: the room is still there
	a.conn.CloseNow()
	b.waitFor(`"away"`)
	time.Sleep(1500 * time.Millisecond)
	a = dial(t, ctx, url)
	a.send(back)
	if m := a.waitFor(`"start"`); m["resume"] != true {
		t.Fatalf("unexpected resume: %v", m)
	}
	// both away: after the time the room is gone, the token too
	a.conn.CloseNow()
	b.conn.CloseNow()
	time.Sleep(1500 * time.Millisecond)
	a = dial(t, ctx, url)
	a.send(back)
	if m := a.waitFor(`"error"`); m["e"] != "expired" {
		t.Fatalf("the empty room should be closed: %v", m)
	}
}
