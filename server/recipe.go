package main

import (
	"bytes"
	"context"
	_ "embed"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// Recipes of the matches played on the phone (campaign, training): the phone
// sends the recipe (sim/replay.lua) at the end of the match and the server
// replays it in a luajit of its own (server/verify.lua), then writes in the
// log whether it came out the same. Guest profiles plan, PR 1: it measures
// whether a match is identical on the phone (ARM, or plain Lua on the web)
// and on the server (x86); later the same check confirms the rewards of the
// matches played without the net. Nothing is paid or saved for now.

//go:embed verify.lua
var verifyLua []byte

// RecipeDir (main.go, -ricette): where the recipes that don't come out the
// same are kept, to study them; "" = not kept.
var RecipeDir = ""

const (
	recipeMax     = 4 << 20          // bytes of a recipe at most
	recipeTimeout = 60 * time.Second // a replay longer than this is stopped
)

// one replay at a time (another one arriving meanwhile gets 503 and is not
// queued), at the lowest priority, so the matches online never wait for it
var recipeSlot = make(chan struct{}, 1)

// RecipeCheck is verify.lua's answer.
type RecipeCheck struct {
	Err         string `json:"err,omitempty"`
	Physics     bool   `json:"physics"`
	PhysicsTick int    `json:"physics_tick"`
	Bots        bool   `json:"bots"`
	BotsTick    int    `json:"bots_tick"`
	Ticks       int    `json:"ticks"`
	Ms          int    `json:"ms"`
	BotsMs      int    `json:"bots_ms"`
}

// checkRecipe replays a recipe's text.
func checkRecipe(ctx context.Context, text []byte) (RecipeCheck, error) {
	var c RecipeCheck
	luaDirOnce.Do(writeLuaDir)
	if luaDirErr != nil {
		return c, luaDirErr
	}
	ctx, cancel := context.WithTimeout(ctx, recipeTimeout)
	defer cancel()
	cmd := exec.CommandContext(ctx, LuaJIT, filepath.Join(luaDir, "verify.lua"), luaDir)
	cmd.Stdin = bytes.NewReader(text)
	cmd.Stderr = os.Stderr
	var out bytes.Buffer
	cmd.Stdout = &out
	if err := cmd.Start(); err != nil {
		return c, fmt.Errorf("luajit: %w", err)
	}
	// the lowest priority: the cores go to the live matches first
	lowPriority(cmd.Process.Pid)
	if err := cmd.Wait(); err != nil {
		return c, fmt.Errorf("luajit: %w", err)
	}
	if err := json.Unmarshal(out.Bytes(), &c); err != nil {
		return c, fmt.Errorf("risposta di verify.lua: %w", err)
	}
	return c, nil
}

// clean keeps a short printable piece of what the phone says about itself.
func clean(s string) string {
	s = strings.Map(func(r rune) rune {
		if r < 32 || r == 127 {
			return -1
		}
		return r
	}, s)
	if len(s) > 60 {
		s = s[:60]
	}
	return s
}

func yesNo(ok bool, tick int) string {
	switch {
	case ok:
		return "torna"
	case tick < 0:
		return "errore"
	default:
		return fmt.Sprintf("diversa al tick %d", tick)
	}
}

// handleRecipe: POST /ricetta?p=<platform>&j=<Lua or LuaJIT version>, body =
// the recipe's text. Answers verify.lua's JSON.
func (s *Server) handleRecipe(w http.ResponseWriter, r *http.Request) {
	who := clean(r.URL.Query().Get("p")) + " (" + clean(r.URL.Query().Get("j")) + ")"
	// every request goes into the log, the refused ones too: so it shows
	// whether the phone's recipe arrives at all
	if r.Method != http.MethodPost {
		log.Printf("ricetta da %s: rifiutata, %s invece di POST", who, r.Method)
		http.Error(w, "solo POST", http.StatusMethodNotAllowed)
		return
	}
	text, err := io.ReadAll(http.MaxBytesReader(w, r.Body, recipeMax))
	if err != nil {
		log.Printf("ricetta da %s: rifiutata, non letta: %v", who, err)
		http.Error(w, "ricetta troppo grande", http.StatusRequestEntityTooLarge)
		return
	}
	log.Printf("ricetta da %s: arrivata, %d byte", who, len(text))
	select {
	case recipeSlot <- struct{}{}:
	default:
		log.Printf("ricetta da %s: rifiutata, il server ne sta già rigiocando un'altra", who)
		http.Error(w, "occupato", http.StatusServiceUnavailable)
		return
	}
	defer func() { <-recipeSlot }()
	c, err := checkRecipe(r.Context(), text)
	if err != nil {
		log.Printf("ricetta da %s: non controllata: %v", who, err)
		http.Error(w, "errore", http.StatusInternalServerError)
		return
	}
	if c.Err != "" {
		log.Printf("ricetta da %s: %s", who, c.Err)
	} else {
		log.Printf("ricetta da %s: fisica: %s, bot: %s, %d tick (%.1f s di partita), rigiocata in %d + %d ms",
			who, yesNo(c.Physics, c.PhysicsTick), yesNo(c.Bots, c.BotsTick), c.Ticks, float64(c.Ticks)/60, c.Ms, c.BotsMs)
	}
	if RecipeDir != "" && (c.Err != "" || !c.Physics || !c.Bots) {
		name := filepath.Join(RecipeDir, time.Now().Format("20060102-150405.000")+".lua")
		if err := os.WriteFile(name, text, 0o644); err != nil {
			log.Printf("ricetta non salvata: %v", err)
		}
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(c)
}
