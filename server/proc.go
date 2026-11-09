package main

import (
	"bufio"
	"bytes"
	_ "embed"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"sync"

	megablast "github.com/Sorbolik/MegaBlast"
)

// The simulation runs in LuaJIT, like on the phone: one luajit process per
// worker (sched.go) runs server/worker.lua with the matches of that worker's
// rooms. Go keeps connections, queues and rooms, and on every tick sends the
// process one batch with the commands of all its rooms, then reads the
// answers: one round trip per worker and tick, not per room (Sergio, 9 Nov:
// on gopher-lua a bot was 22 times slower and online they played worse).
// Protocol in server/worker.lua.

//go:embed net.lua
var netLua []byte

//go:embed worker.lua
var workerLua []byte

// LuaJIT is the luajit executable (main.go, -luajit): on the PATH by default.
var LuaJIT = "luajit"

// The Lua files go into a temporary folder once per process: client/sim as
// embedded in the executable, net.lua and worker.lua.
var (
	luaDirOnce sync.Once
	luaDir     string
	luaDirErr  error
)

func writeLuaDir() {
	luaDir, luaDirErr = os.MkdirTemp("", "megablast-lua-")
	if luaDirErr != nil {
		return
	}
	if luaDirErr = os.Mkdir(filepath.Join(luaDir, "sim"), 0o755); luaDirErr != nil {
		return
	}
	entries, err := megablast.SimFS.ReadDir("client/sim")
	if err != nil {
		luaDirErr = err
		return
	}
	// all the modules of client/sim: whoever adds one doesn't have to touch the server
	for _, e := range entries {
		src, err := megablast.SimFS.ReadFile("client/sim/" + e.Name())
		if err == nil {
			err = os.WriteFile(filepath.Join(luaDir, "sim", e.Name()), src, 0o644)
		}
		if err != nil {
			luaDirErr = err
			return
		}
	}
	if luaDirErr = os.WriteFile(filepath.Join(luaDir, "net.lua"), netLua, 0o644); luaDirErr == nil {
		luaDirErr = os.WriteFile(filepath.Join(luaDir, "worker.lua"), workerLua, 0o644)
	}
}

// Proc is a luajit process with the simulation loaded.
type Proc struct {
	mu   sync.Mutex // Run one at a time (the utility process is shared)
	cmd  *exec.Cmd
	in   io.WriteCloser
	w    *bufio.Writer
	r    *bufio.Reader
	dead error
	// answers of the last batch, reused: heads in one buffer (they are read
	// at once by the callbacks), the raws each with its own memory (they go
	// to the players as they are)
	heads []byte
	spans [][2]int
	raws  [][][]byte
}

func startProc() (*Proc, error) {
	luaDirOnce.Do(writeLuaDir)
	if luaDirErr != nil {
		return nil, luaDirErr
	}
	cmd := exec.Command(LuaJIT, filepath.Join(luaDir, "worker.lua"), luaDir)
	cmd.Stderr = os.Stderr
	in, err := cmd.StdinPipe()
	if err != nil {
		return nil, err
	}
	out, err := cmd.StdoutPipe()
	if err != nil {
		return nil, err
	}
	if err := cmd.Start(); err != nil {
		return nil, fmt.Errorf("luajit (%s): %w", LuaJIT, err)
	}
	return &Proc{cmd: cmd, in: in, w: bufio.NewWriterSize(in, 64<<10), r: bufio.NewReaderSize(out, 256<<10)}, nil
}

// Close stops the process (it ends by itself when its input closes).
func (p *Proc) Close() {
	p.in.Close()
	p.cmd.Process.Kill()
	p.cmd.Wait()
}

// Result is a command's answer: Head is the small part Go reads, Raw the
// messages already in JSON. Err: the command failed in Lua.
type Result struct {
	Head []byte
	Raw  [][]byte
	Err  error
}

// Run sends the batch and reads its answers, then calls the commands'
// callbacks in order; next is the batch of the next tick, where callbacks
// add their commands (a room that closes). An error means the process is no
// longer usable: no callback has been called.
func (p *Proc) Run(b *Batch, next *Batch) error {
	if len(b.cbs) == 0 {
		return nil
	}
	p.mu.Lock()
	defer p.mu.Unlock()
	if err := p.roundTrip(b); err != nil {
		return err
	}
	res := make([]Result, len(b.cbs))
	for i := range res {
		sp := p.spans[i]
		res[i].Head, res[i].Raw = p.heads[sp[0]:sp[1]], p.raws[i]
		if bytes.HasPrefix(res[i].Head, []byte(`{"err":`)) {
			var e struct {
				Err string `json:"err"`
			}
			json.Unmarshal(res[i].Head, &e)
			res[i].Err = errors.New(e.Err)
		}
	}
	// heads are only valid until the next Run: the callbacks read them now
	// (still under the lock, so they must not call Run on the same process)
	for i, cb := range b.cbs {
		if cb != nil {
			cb(next, res[i])
		}
	}
	return nil
}

func (p *Proc) roundTrip(b *Batch) error {
	if p.dead != nil {
		return p.dead
	}
	b.flush()
	p.heads, p.spans = p.heads[:0], p.spans[:0]
	clear(p.raws)
	p.raws = p.raws[:0]
	fail := func(err error) error {
		p.dead = fmt.Errorf("processo luajit: %w", err)
		p.Close()
		return p.dead
	}
	if _, err := p.w.Write(b.data); err != nil {
		return fail(err)
	}
	if err := p.w.WriteByte('\n'); err != nil {
		return fail(err)
	}
	if err := p.w.Flush(); err != nil {
		return fail(err)
	}
	for range b.cbs {
		line, err := p.r.ReadSlice('\n')
		if err != nil {
			return fail(err)
		}
		nraw, hlen, ok := twoInts(line)
		if !ok {
			return fail(fmt.Errorf("risposta illeggibile %q", line))
		}
		start := len(p.heads)
		p.heads = append(p.heads, make([]byte, hlen)...)
		if _, err := io.ReadFull(p.r, p.heads[start:]); err != nil {
			return fail(err)
		}
		p.spans = append(p.spans, [2]int{start, len(p.heads)})
		var raws [][]byte
		for j := 0; j < nraw; j++ {
			line, err := p.r.ReadSlice('\n')
			if err != nil {
				return fail(err)
			}
			n, _, ok := twoInts(line)
			if !ok {
				return fail(fmt.Errorf("risposta illeggibile %q", line))
			}
			raw := make([]byte, n)
			if _, err := io.ReadFull(p.r, raw); err != nil {
				return fail(err)
			}
			raws = append(raws, raw)
		}
		p.raws = append(p.raws, raws)
	}
	return nil
}

// twoInts reads "a b\n" or "a\n" (b is then 0). On Windows luajit writes
// stdout in text mode, so lines end in "\r\n": the \r is skipped (the
// messages are JSON, they never hold a real newline).
func twoInts(line []byte) (a, b int, ok bool) {
	n, cur := 0, &a
	for _, c := range line {
		switch {
		case c >= '0' && c <= '9':
			*cur = *cur*10 + int(c-'0')
			n++
		case c == ' ' && cur == &a && n > 0:
			cur, n = &b, 0
		case c == '\r':
		case c == '\n':
			return a, b, n > 0
		default:
			return 0, 0, false
		}
	}
	return 0, 0, false
}

// Batch is the commands of one tick for a process, written as Lua tables
// (server/worker.lua): Cmd opens one, the field methods add to it, End
// closes it. Lines of at most chunkMax commands (a Lua function has a limit
// of constants).
type Batch struct {
	data  []byte // finished lines
	chunk []byte // commands of the current line
	n     int    // how many in chunk
	cbs   []func(next *Batch, res Result)
}

const chunkMax = 200

func (b *Batch) Len() int { return len(b.cbs) }

func (b *Batch) Reset() {
	b.data, b.chunk, b.n = b.data[:0], b.chunk[:0], 0
	clear(b.cbs)
	b.cbs = b.cbs[:0]
}

// Cmd starts command f for room r; cb (can be nil) receives its answer.
func (b *Batch) Cmd(f string, room int64, cb func(next *Batch, res Result)) *Batch {
	if b.n == chunkMax {
		b.flush()
	}
	if b.n > 0 {
		b.chunk = append(b.chunk, ',')
	}
	b.n++
	b.cbs = append(b.cbs, cb)
	b.chunk = append(b.chunk, `{f="`...)
	b.chunk = append(b.chunk, f...)
	b.chunk = append(b.chunk, `",r=`...)
	b.chunk = strconv.AppendInt(b.chunk, room, 10)
	return b
}

func (b *Batch) End() { b.chunk = append(b.chunk, '}') }

func (b *Batch) key(k string) {
	if b.chunk[len(b.chunk)-1] != '{' { // first field of a nested table
		b.chunk = append(b.chunk, ',')
	}
	b.chunk = append(b.chunk, k...)
	b.chunk = append(b.chunk, '=')
}

func (b *Batch) Int(k string, v int64) *Batch {
	b.key(k)
	b.chunk = strconv.AppendInt(b.chunk, v, 10)
	return b
}

func (b *Batch) Num(k string, v float64) *Batch {
	b.key(k)
	b.chunk = appendLuaNum(b.chunk, v)
	return b
}

func (b *Batch) Str(k, v string) *Batch {
	b.key(k)
	b.chunk = appendLuaString(b.chunk, v)
	return b
}

// Bool adds the field only when true (missing is false in Lua).
func (b *Batch) Bool(k string, v bool) *Batch {
	if v {
		b.key(k)
		b.chunk = append(b.chunk, "true"...)
	}
	return b
}

// Lit adds a value already written as Lua (luaFromJSON); nothing if empty.
func (b *Batch) Lit(k string, lit []byte) *Batch {
	if len(lit) > 0 {
		b.key(k)
		b.chunk = append(b.chunk, lit...)
	}
	return b
}

// Raw writes Lua as it is (a nested table being built).
func (b *Batch) Raw(s string) *Batch {
	b.chunk = append(b.chunk, s...)
	return b
}

func (b *Batch) flush() {
	if b.n == 0 {
		return
	}
	b.data = strconv.AppendInt(b.data, int64(b.n), 10)
	b.data = append(b.data, "\t{"...)
	b.data = append(b.data, b.chunk...)
	b.data = append(b.data, "}\n"...)
	b.chunk, b.n = b.chunk[:0], 0
}

func appendLuaNum(b []byte, f float64) []byte {
	if math.IsNaN(f) || math.IsInf(f, 0) {
		return append(b, '0')
	}
	return strconv.AppendFloat(b, f, 'g', -1, 64)
}

// appendLuaString quotes s for Lua: every byte that isn't printable ASCII,
// and quotes and backslashes, as \ddd. What the players send (weapon names)
// can't get out of the string.
func appendLuaString(b []byte, s string) []byte {
	b = append(b, '"')
	for i := 0; i < len(s); i++ {
		c := s[i]
		if c < 0x20 || c > 0x7e || c == '"' || c == '\\' {
			b = append(b, '\\', '0'+c/100, '0'+c/10%10, '0'+c%10)
			continue
		}
		b = append(b, c)
	}
	return append(b, '"')
}

// luaFromJSON writes a JSON (event rules, sim/rules.lua) as a Lua value:
// objects and lists become tables, null nil. nil gives nil (no field).
func luaFromJSON(data []byte) ([]byte, error) {
	if data == nil {
		return nil, nil
	}
	var v any
	if err := json.Unmarshal(data, &v); err != nil {
		return nil, err
	}
	return appendLuaValue(nil, v), nil
}

func appendLuaValue(b []byte, v any) []byte {
	switch v := v.(type) {
	case map[string]any:
		keys := make([]string, 0, len(v))
		for k := range v {
			keys = append(keys, k)
		}
		sort.Strings(keys) // the same Lua for the same JSON
		b = append(b, '{')
		for i, k := range keys {
			if i > 0 {
				b = append(b, ',')
			}
			b = append(b, '[')
			b = appendLuaString(b, k)
			b = append(b, "]="...)
			b = appendLuaValue(b, v[k])
		}
		return append(b, '}')
	case []any:
		b = append(b, '{')
		for i, x := range v {
			if i > 0 {
				b = append(b, ',')
			}
			b = appendLuaValue(b, x)
		}
		return append(b, '}')
	case float64:
		return appendLuaNum(b, v)
	case string:
		return appendLuaString(b, v)
	case bool:
		return strconv.AppendBool(b, v)
	default:
		return append(b, "nil"...)
	}
}

// The utility process: for what isn't a room's (events.go checking an
// event's rules, the tests). Started the first time it's needed, restarted
// if it dies.
var (
	utilMu   sync.Mutex
	utilProc *Proc
)

// callUtil runs a batch of one command on the utility process and returns
// its answer.
func callUtil(b *Batch) (Result, error) {
	utilMu.Lock()
	p := utilProc
	if p == nil || p.dead != nil {
		var err error
		if p, err = startProc(); err != nil {
			utilMu.Unlock()
			return Result{}, err
		}
		utilProc = p
	}
	utilMu.Unlock()
	return callOne(p, b)
}

// callOne runs on p a batch with a single command (its callback is replaced).
func callOne(p *Proc, b *Batch) (Result, error) {
	var res Result
	b.cbs[0] = func(_ *Batch, r Result) {
		res = Result{Head: append([]byte(nil), r.Head...), Raw: r.Raw, Err: r.Err}
	}
	if err := p.Run(b, nil); err != nil {
		return Result{}, err
	}
	return res, res.Err
}

// rulesValid: can an event's rules be used? "" if yes, otherwise why not
// (sim/rules.lua validate; normal: the event has no teams of its own).
func rulesValid(rules []byte, normal bool) (string, error) {
	lit, err := luaFromJSON(rules)
	if err != nil {
		return "", err
	}
	b := &Batch{}
	b.Cmd("rules_valid", 0, nil).Lit("rules", lit).Bool("normal", normal).End()
	res, err := callUtil(b)
	if err != nil {
		return "", err
	}
	var v struct {
		Msg string `json:"msg"`
	}
	if err := json.Unmarshal(res.Head, &v); err != nil {
		return "", err
	}
	return v.Msg, nil
}
