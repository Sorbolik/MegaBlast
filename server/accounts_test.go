package main

import (
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"strings"
	"testing"
)

func accountsServer(t *testing.T) (string, *Accounts) {
	t.Helper()
	acc, err := OpenAccounts(filepath.Join(t.TempDir(), "megablast.db"))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { acc.Close() })
	s := NewServer(DefaultConfig())
	s.accounts = acc
	srv := httptest.NewServer(s.Handler())
	t.Cleanup(srv.Close)
	return srv.URL, acc
}

func postProfile(t *testing.T, url, auth, body string) (int, []byte) {
	t.Helper()
	req, _ := http.NewRequest(http.MethodPost, url, strings.NewReader(body))
	if auth != "" {
		req.Header.Set("Authorization", auth)
	}
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatal(err)
	}
	defer res.Body.Close()
	b, _ := io.ReadAll(res.Body)
	return res.StatusCode, b
}

// A phone with progress gets an identity and its profile cut to the caps
// (sim/profile.lua, import); with its key it reads the profile back and has
// its actions done by the server's rules (sim/progress.lua), each once; with
// another key nothing.
func TestGuestProfiles(t *testing.T) {
	url, acc := accountsServer(t)
	var phone string
	luaEval(t, `
		local profile = require "sim.profile"
		local replay = require "sim.replay"
		local p = profile.new()
		p.livello, p.scaglie, p.ossidiana = 45, 999999, 12
		p.pezzi.corvo_mask, p.posseduti.corvo_mask = 28, true
		p.loadouts[1].gear.mask = "corvo"
		p.loadouts[1].gear.chest = "fornace"
		p.impostazioni.mira = "dito"
		return replay.write(p)`, &phone)

	code, body := postProfile(t, url+"/profilo/nuovo?p=prova", "", phone)
	if code != http.StatusOK {
		t.Fatalf("nuovo: %d %s", code, body)
	}
	var a Account
	if err := json.Unmarshal(body, &a); err != nil {
		t.Fatal(err)
	}
	if a.ID <= 0 || len(a.Key) < 32 || a.Rev != 1 || !strings.HasPrefix(a.Name, "Diavoletto ") {
		t.Fatalf("identità: %+v", a)
	}
	var got []any
	luaEval(t, `
		local p = require("sim.replay").read(`+luaQuote(a.Profile)+`)
		return { p.livello, p.scaglie, p.ossidiana, p.pezzi.corvo_mask, p.loadouts[1].gear.mask or "", p.loadouts[1].gear.chest or "", p.impostazioni.mira or "", p.nome }`, &got)
	want := []any{30.0, 20000.0, 12.0, 20.0, "corvo", "", "", a.Name}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("import: %v, attesi %v", got, want)
		}
	}

	auth := "Profilo " + itoa(a.ID) + "." + a.Key
	// no actions: the server's profile as it is
	if code, body = postProfile(t, url+"/profilo/fai", auth, ""); code != http.StatusOK {
		t.Fatalf("profilo: %d %s", code, body)
	}
	var back Account
	json.Unmarshal(body, &back)
	if back.ID != a.ID || back.Key != "" || back.Profile != a.Profile {
		t.Fatalf("profilo riletto: %+v", back)
	}
	if code, _ = postProfile(t, url+"/profilo/fai", "Profilo "+itoa(a.ID)+".sbagliata", ""); code != http.StatusUnauthorized {
		t.Fatalf("chiave sbagliata: %d", code)
	}
	// the phone's actions, with the server's rules: a piece bought, a signature
	// without the Ossidiana for it; sent again, nothing happens twice
	actions := `{["azioni"]={{["n"]=1,["k"]="compra",["set"]="fornace",["slot"]="chest"},{["n"]=2,["k"]="firma",["set"]="corvo",["slot"]="mask"}}}`
	for i := 0; i < 2; i++ {
		if code, body = postProfile(t, url+"/profilo/fai", auth, actions); code != http.StatusOK {
			t.Fatalf("azioni %d: %d %s", i, code, body)
		}
		json.Unmarshal(body, &back)
		var sc float64
		luaEval(t, `return require("sim.replay").read(`+luaQuote(back.Profile)+`).scaglie`, &sc)
		if back.Last != 2 || sc != 20000-4800 {
			t.Fatalf("azioni %d: ultima %d, %v Scaglie", i, back.Last, sc)
		}
	}
	// a match whose recipe doesn't come back: done (it isn't sent again) but not paid
	bad := `{["azioni"]={{["n"]=3,["k"]="partita",["ricetta"]="x"}}}`
	if code, body = postProfile(t, url+"/profilo/fai", auth, bad); code != http.StatusOK {
		t.Fatalf("partita: %d %s", code, body)
	}
	back = Account{}
	json.Unmarshal(body, &back)
	if back.Last != 3 || len(back.Refused) != 1 || back.Refused[0] != 3 {
		t.Fatalf("partita non valida: ultima %d, rifiutate %v", back.Last, back.Refused)
	}
	if code, _ = postProfile(t, url+"/profilo/fai", auth, "{"); code != http.StatusBadRequest {
		t.Fatalf("azioni illeggibili: %d", code)
	}
	var rows []string
	r, err := acc.db.Query(`SELECT tipo FROM registro WHERE giocatore = ? ORDER BY id`, a.ID)
	if err != nil {
		t.Fatal(err)
	}
	for r.Next() {
		var k string
		r.Scan(&k)
		rows = append(rows, k)
	}
	r.Close()
	if strings.Join(rows, ",") != "import,azioni,azioni" {
		t.Fatalf("registro: %v", rows)
	}
	// a profile of PR 3, whose phone sent copies: the latest becomes the server's
	b, _, _ := acc.New("")
	if _, err := acc.db.Exec(`UPDATE giocatori SET copia = ? WHERE id = ?`, phone, b.ID); err != nil {
		t.Fatal(err)
	}
	if code, body = postProfile(t, url+"/profilo/fai", "Profilo "+itoa(b.ID)+"."+b.Key, ""); code != http.StatusOK {
		t.Fatalf("padrone: %d %s", code, body)
	}
	json.Unmarshal(body, &back)
	var lv float64
	luaEval(t, `return require("sim.replay").read(`+luaQuote(back.Profile)+`).livello`, &lv)
	if lv != 30 {
		t.Fatalf("padrone: livello %v, atteso 30 (la copia, tagliata)", lv)
	}
	// a profile from nothing
	if code, body = postProfile(t, url+"/profilo/nuovo", "", ""); code != http.StatusOK {
		t.Fatalf("nuovo da zero: %d %s", code, body)
	}
}

func itoa(n int64) string {
	b, _ := json.Marshal(n)
	return string(b)
}

// s as a Lua long string
func luaQuote(s string) string { return "[==[" + s + "]==]" }
