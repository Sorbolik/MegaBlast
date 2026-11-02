package main

import (
	"encoding/json"
	"os"
	"reflect"
	"testing"
)

// The events panel (strumenti/eventi) checks events with the data in
// pagina/dati.json: it must match the simulation, otherwise the panel lets
// through an event the server rejects. If it fails:
// luajit strumenti/eventi/dati.lua
func TestPanelData(t *testing.T) {
	file, err := os.ReadFile("../strumenti/eventi/pagina/dati.json")
	if err != nil {
		t.Fatal(err)
	}
	eng, err := newEngine()
	if err != nil {
		t.Fatal(err)
	}
	defer eng.L.Close()
	err = eng.L.DoString(`
		local C, game = require "sim.config", require "sim.game"
		local regole, equip = require "sim.rules", require "sim.gear"
		local modi, normale = {}, {}
		for m, p in pairs(C.MODES) do modi[m] = #p end
		for k in pairs(regole.CODA_NORMALE) do normale[#normale + 1] = k end
		table.sort(normale)
		dati_pannello = { primarie = game.CRATE_WEAPONS, secondarie = game.DRAFT_SECONDARIES, punti = C.SCORE,
			casse = game.CRATE_EVERY, tetto_max = equip.LIVELLO_MAX - 1, modi = modi, coda_normale = normale }`)
	if err != nil {
		t.Fatal(err)
	}
	type data struct {
		Primaries   []string           `json:"primarie"`
		Secondaries []string           `json:"secondarie"`
		Points      map[string]float64 `json:"punti"`
		Crates      int                `json:"casse"`
		CapMax      int                `json:"tetto_max"`
		ModeSizes   map[string]int     `json:"modi"`
		NormalQueue []string           `json:"coda_normale"`
	}
	var inPanel, nellaSim data
	if err := json.Unmarshal(file, &inPanel); err != nil {
		t.Fatal(err)
	}
	if err := json.Unmarshal(appendJSON(nil, eng.L.GetGlobal("dati_pannello")), &nellaSim); err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(inPanel, nellaSim) {
		t.Fatalf("strumenti/eventi/pagina/dati.json is out of sync with the simulation: luajit strumenti/eventi/dati.lua\npanel %+v\nsimulation %+v", inPanel, nellaSim)
	}
}
