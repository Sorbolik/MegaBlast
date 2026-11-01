-- Armeria: i 3 assetti del giocatore (docs/game_design_competitivo.md, regola 4
-- dell'albero: ricostruzione gratuita fuori dalla partita, 3 assetti salvati).
-- Due schede:
--   SET    un set dei Titani per ogni pezzo (sidegrade), tier dalla maestria,
--          bonus a set completo e variante B coi pezzi al livello 30;
--   ALBERO i punti abilità nei tre rami (sim/abilita.lua).
-- A destra le statistiche che ne vengono fuori, rispetto alla base.
--
-- La schermata si ricostruisce da capo a ogni tocco: pochi nodi, solo quando
-- si tocca, e nessuno stato da tenere allineato.
--
-- Uso: local a = armeria.new(profilo) ; armeria.on_input(a, action_id, action) -> "indietro" o nil
--      armeria.distruggi(a)

local ui = require "ui.ui"
local game = require "sim.game"
local abilita = require "sim.abilita"
local equip = require "sim.equipaggiamento"
local assetto = require "sim.assetto"
local profilo = require "menu.profilo"

local M = {}

-- statistiche mostrate a destra, in quest'ordine: nome e come si scrive il valore
M.STATISTICHE = {
	{ "max_hp", "Vita" }, { "walk_speed", "Corsa" }, { "jump_height", "Salto" }, { "air_speed", "In aria" },
	{ "teleport_ticks", "Teletrasporto", "secondi" }, { "teleports", "Teletrasporti" },
	{ "parachutes", "Paracadute" }, { "air_jumps", "Salti in aria" },
	{ "fall_damage_mul", "Danno da caduta", "percento" }, { "knockback_mul", "Spinta subita", "percento" },
	{ "trap_radius", "Raggio trappole" }, { "status_turns", "Turni degli effetti" },
	{ "burning_blasts", "Colpi brucianti", "sì" },
}
local ROMANI = { "I", "II", "III", "IV" }
local NOMI_STAT = {}
for _, s in ipairs(M.STATISTICHE) do NOMI_STAT[s[1]] = string.lower(s[2]) end

local function vec(x, y) return vmath.vector3(x, y, 0) end

local function base()
	return game.base_stats()
end

local function valore(v, modo)
	if type(v) ~= "number" then return v and "sì" or "no" end
	if modo == "secondi" then return string.format("%.1f s", v / 60) end
	if modo == "sì" then return v > 0 and "sì" or "no" end
	if modo == "percento" then return string.format("%d%%", math.floor(v * 100 + 0.5)) end
	if v % 1 ~= 0 then return string.format("%.1f", v) end
	return tostring(v)
end

-- "+3 salto, -2 vita": gli effetti di un pezzo in breve
local function effetti(lista)
	local t = {}
	for _, e in ipairs(lista) do
		local n = e.add or e.mul
		local s = e.add and string.format("%+g", n) or string.format("%+d%%", math.floor((n - 1) * 100 + 0.5))
		t[#t + 1] = s .. " " .. (NOMI_STAT[e.stat] or e.stat)
	end
	return table.concat(t, ", ")
end

local function a_attivo(a) return profilo.assetto_attivo(a.prof) end

-- Statistiche ------------------------------------------------------------------

local function statistiche(a, parent)
	local c = ui.C
	local b = base()
	local st = assetto.stats(b, a_attivo(a), profilo.tier(a.prof, a_attivo(a)))
	local pan = ui.pannello(1135, 330, 250, 560, parent)
	ui.titolo("STATISTICHE", 0, 255, 0.6, c.TESTO, pan)
	local y = 215
	for _, s in ipairs(M.STATISTICHE) do
		local k, nome, modo = s[1], s[2], s[3]
		if st[k] ~= nil then
			local diff = b[k] ~= nil and st[k] ~= b[k]
			local col = c.SPENTO
			if diff then
				local meglio = type(st[k]) ~= "number" or st[k] > b[k]
				-- per questi meno è meglio
				if k == "teleport_ticks" or k == "fall_damage_mul" or k == "knockback_mul" then
					meglio = st[k] < b[k]
				end
				col = meglio and c.BRACE or c.TESTO
			end
			local n = ui.testo(nome, -110, y, 0.7, c.SPENTO, pan)
			gui.set_pivot(n, gui.PIVOT_W)
			local v = ui.testo(valore(st[k], modo), 110, y, 0.75, col, pan)
			gui.set_pivot(v, gui.PIVOT_E)
			y = y - 30
		end
	end
end

-- Scheda SET -------------------------------------------------------------------

local function scheda_set(a, parent)
	local c = ui.C
	local as = a_attivo(a)
	local tiers = profilo.tier(a.prof, as)
	for r, slot in ipairs(equip.SLOTS) do
		local y = 540 - (r - 1) * 92
		ui.testo(slot.name, 110, y, 0.8, c.TESTO, parent)
		for i, set in ipairs(equip.SETS) do
			local scelto = as.gear[slot.id] == set.id
			local x = 260 + (i - 1) * 138
			local t = equip.tier(a.prof.maestria[set.id .. "_" .. slot.id])
			ui.scheda(a.bottoni, x, y + 8, 130, 46, set.name, "set:" .. slot.id .. ":" .. set.id, scelto, parent)
			ui.testo("tier " .. ROMANI[t], x, y - 26, 0.55, scelto and c.BRACE or c.SPENTO, parent)
		end
		local pezzo = equip.BY_ID[as.gear[slot.id] or ""]
		local n = ui.testo(pezzo and effetti(pezzo.pieces[slot.id]) or "nessun pezzo", 770, y, 0.6, c.SPENTO, parent)
		gui.set_pivot(n, gui.PIVOT_W)
	end

	-- bonus del set completo, se quel set ne ha uno
	local id, top = equip.full_set(as.gear, tiers)
	local set = id and equip.BY_ID[id]
	if not (set and set.bonus) then return end
	local pan = ui.pannello(510, 140, 940, 130, parent)
	ui.titolo(set.name .. " · " .. string.upper(set.style), -200, 38, 0.7, c.BRACE, pan)
	for i, v in ipairs({ "a", "b" }) do
		local y = 4 - (i - 1) * 40
		local ok = v == "a" or top
		ui.scheda(a.bottoni, -420, y, 50, 34, string.upper(v), "variante:" .. v, as.variant == v and (v == "a" or top), pan)
		local testo = set.bonus[v].desc .. (ok and "" or "  (tutti i pezzi al livello " .. equip.LIVELLO_MAX .. ")")
		local n = ui.testo(testo, -380, y, 0.62, ok and c.TESTO or c.SPENTO, pan)
		gui.set_pivot(n, gui.PIVOT_W)
	end
end

-- Scheda ALBERO ----------------------------------------------------------------

local function scheda_albero(a, parent)
	local c = ui.C
	local tree = a_attivo(a).tree
	local punti = profilo.punti(a.prof)
	-- colonne dei rami nello spazio a sinistra delle statistiche
	local passo = math.min(440, 990 / #abilita.BRANCHES)
	for b, ramo in ipairs(abilita.BRANCHES) do
		local x = 510 + (b - (#abilita.BRANCHES + 1) / 2) * passo
		ui.titolo(ramo.name, x, 575, 0.7, c.TESTO, parent)
		ui.testo(string.format("%d punti", abilita.spent(tree, ramo.id)), x, 548, 0.6, c.SPENTO, parent)
		-- nodi per riga
		local righe = {}
		for _, n in ipairs(abilita.NODES) do
			if n.branch == ramo.id then
				righe[n.row] = righe[n.row] or {}
				table.insert(righe[n.row], n)
			end
		end
		for r, lista in ipairs(righe) do
			local y = 490 - (r - 1) * 100
			for i, nodo in ipairs(lista) do
				local nx = x + (i - (#lista + 1) / 2) * 156
				local gradi = tree[nodo.id] or 0
				local ok = gradi > 0 or abilita.can_add(tree, nodo.id, punti)
				local btn = ui.scheda(a.bottoni, nx, y, 150, 80, "", "nodo:" .. nodo.id, gradi > 0, parent)
				local col = ok and c.TESTO or c.SPENTO
				ui.testo(nodo.name, 0, 22, 0.75, col, btn)
				ui.testo(string.format("%d / %d", gradi, nodo.ranks), 0, -4, 1.3, gradi > 0 and c.BRACE or col, btn)
				ui.testo(nodo.cost == 1 and "1 punto" or (nodo.cost .. " punti"), 0, -28, 0.8, c.SPENTO, btn)
				if gradi > 0 and abilita.can_remove(tree, nodo.id) then
					ui.bottone(a.bottoni, 62, -26, 26, 26, "-", "togli:" .. nodo.id, nil, btn)
				end
			end
		end
	end
	-- in basso: punti, nodo scelto, ricostruzione
	local pan = ui.pannello(510, 70, 940, 90, parent)
	ui.testo(string.format("PUNTI %d / %d", abilita.spent(tree), punti), -360, 18, 0.9, c.BRACE, pan)
	ui.testo(string.format("livello %d", a.prof.livello), -360, -14, 0.55, c.SPENTO, pan)
	local nodo = abilita.BY_ID[a.ultimo or ""]
	if nodo then
		ui.testo(nodo.name, 30, 18, 0.75, c.TESTO, pan)
		ui.testo(nodo.desc .. " per grado", 30, -12, 0.6, c.SPENTO, pan)
	end
	ui.bottone(a.bottoni, 380, 0, 140, 50, "AZZERA", "azzera", nil, pan)
end

-- Schermata --------------------------------------------------------------------

local function costruisci(a)
	if a.radice then gui.delete_node(a.radice) end
	a.bottoni = {}
	a.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(a.radice, false)
	local c = ui.C
	ui.indietro(a.bottoni, "indietro", a.radice)
	ui.titolo("ARMERIA", 220, 680, 1, c.TESTO, a.radice)
	ui.scheda(a.bottoni, 470, 680, 150, 48, "SET", "scheda:set", a.scheda == "set", a.radice)
	ui.scheda(a.bottoni, 630, 680, 150, 48, "ALBERO", "scheda:albero", a.scheda == "albero", a.radice)
	ui.testo("ASSETTO", 900, 680, 0.7, c.SPENTO, a.radice)
	for i = 1, assetto.LOADOUTS do
		ui.scheda(a.bottoni, 940 + i * 70, 680, 60, 48, tostring(i), "assetto:" .. i, a.prof.attivo == i, a.radice)
	end
	if a.scheda == "set" then scheda_set(a, a.radice) else scheda_albero(a, a.radice) end
	statistiche(a, a.radice)
end

function M.new(prof)
	local a = { prof = prof, scheda = "set" }
	a.fondo = ui.sfondo()
	costruisci(a)
	return a
end

-- azioni dei bottoni: "tipo:argomento[:altro]"
local function esegui(a, azione)
	local tipo, x, y = azione:match("^(%a+):?([^:]*):?(.*)$")
	local as = a_attivo(a)
	if tipo == "scheda" then
		a.scheda = x
	elseif tipo == "assetto" then
		a.prof.attivo = tonumber(x)
	elseif tipo == "set" then
		-- toccare il set già scelto lo toglie
		as.gear[x] = as.gear[x] ~= y and y or nil
	elseif tipo == "variante" then
		local _, top = equip.full_set(as.gear, profilo.tier(a.prof, as))
		if x == "a" or top then as.variant = x end
	elseif tipo == "nodo" then
		a.ultimo = x
		if abilita.can_add(as.tree, x, profilo.punti(a.prof)) then as.tree[x] = (as.tree[x] or 0) + 1 end
	elseif tipo == "togli" then
		a.ultimo = x
		if abilita.can_remove(as.tree, x) then
			as.tree[x] = as.tree[x] - 1
			if as.tree[x] == 0 then as.tree[x] = nil end
		end
	elseif tipo == "azzera" then
		as.tree = {}
	end
	profilo.salva(a.prof)
	costruisci(a)
end

function M.on_input(a, action_id, action)
	local azione = ui.tocco(a.bottoni, action_id, action)
	if azione == "indietro" then return "indietro" end
	if azione then esegui(a, azione) end
	return nil
end

function M.distruggi(a)
	gui.delete_node(a.radice)
	gui.delete_node(a.fondo)
end

return M
