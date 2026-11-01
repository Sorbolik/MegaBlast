-- Profilo del giocatore sul telefono: livello, maestria dei pezzi, i 3
-- assetti, le statistiche coi badge e le ultime partite. Finché il server non tiene gli account si salva in locale (sys.save); la logica è Lua puro e si prova nei test.
--
-- Progressione (docs/game_design_competitivo.md, "Più avanti: reward e
-- progressione"): ogni partita dà esperienza (anche persa, di più sul podio);
-- il livello dà i punti dell'albero; giocare con un pezzo ne alza il tier.
-- Le Scorie (materiale della Forgia) arriveranno con la Forgia.

local abilita = require "sim.abilita"
local assetto = require "sim.assetto"
local equip = require "sim.equipaggiamento"
local traguardi = require "menu.traguardi"

local M = {}

M.VERSIONE = 1
-- esperienza per posto (1°, 2°, 3°, 4°) e per ogni riconoscimento
M.XP_POSTO = { 120, 80, 60, 50 }
M.XP_RICONOSCIMENTO = 25
-- esperienza per passare dal livello n al n + 1: XP_BASE + XP_PASSO * (n - 1)
M.XP_BASE, M.XP_PASSO = 100, 25

-- Le impostazioni e i loro valori di base (docs/impostazioni.md)
-- (tasti: i tasti del controller cambiati, tasto -> comando; nil è la mappatura di base, ui/controller.lua)
-- (sparo: col controller il colpo parte premendo o lasciando il tasto; potenza:
-- col controller la dà la levetta destra o quanto è premuto il grilletto)
M.IMPOSTAZIONI = { mira = "lancetta", sparo = "rilascio", potenza = "levetta", levette = "destra" }

function M.impostazione(p, chiave)
	local v = p and p.impostazioni and p.impostazioni[chiave]
	if v == nil then return M.IMPOSTAZIONI[chiave] end
	return v
end

function M.imposta(p, chiave, valore)
	p.impostazioni = p.impostazioni or {}
	p.impostazioni[chiave] = valore
end

function M.nuovo()
	local p = { versione = M.VERSIONE, xp = 0, livello = 1, maestria = {}, assetti = {}, attivo = 1, stelle = {}, fallite = {},
		armi = {}, impostazioni = {}, statistiche = {}, partite = {}, badge = {}, serie = 0, numero = 0 }
	for i = 1, assetto.LOADOUTS do p.assetti[i] = assetto.new() end
	return p
end

-- esperienza che serve per salire dal livello n
function M.xp_livello(n)
	return M.XP_BASE + M.XP_PASSO * (n - 1)
end

function M.punti(p)
	return abilita.points(p.livello)
end

-- tier dei pezzi indossati da un assetto: { mask = 1..3, ... }
function M.tier(p, a)
	local t = {}
	for _, s in ipairs(equip.SLOTS) do
		local set = a.gear[s.id]
		t[s.id] = set and equip.tier(p.maestria[set .. "_" .. s.id]) or 1
	end
	return t
end

function M.assetto_attivo(p)
	return p.assetti[p.attivo]
end

-- Fine partita: posto (1..4) e riconoscimenti presi. Aggiorna il profilo e
-- restituisce cosa si è guadagnato { xp, livello_prima, livello }.
function M.fine_partita(p, posto, riconoscimenti)
	local g = {
		xp = (M.XP_POSTO[posto] or M.XP_POSTO[#M.XP_POSTO]) + M.XP_RICONOSCIMENTO * #(riconoscimenti or {}),
		livello_prima = p.livello,
	}
	p.xp = p.xp + g.xp
	while p.xp >= M.xp_livello(p.livello) do
		p.xp = p.xp - M.xp_livello(p.livello)
		p.livello = p.livello + 1
	end
	g.livello = p.livello
	-- maestria: una partita in più per ogni pezzo indossato
	local a = M.assetto_attivo(p)
	for _, s in ipairs(equip.SLOTS) do
		local set = a.gear[s.id]
		if set then
			local k = set .. "_" .. s.id
			p.maestria[k] = (p.maestria[k] or 0) + 1
		end
	end
	return g
end

-- Statistiche, badge e partite (scheda personaggio, Sergio 31 ott) ---------------

-- I gruppi delle statistiche, come i filtri della scheda STATISTICHE. TUTTE
-- non si salva: si somma (i record col massimo)
M.GRUPPI = { "2v2", "1v1", "torneo", "campagna", "tutte" }
M.NOMI_GRUPPI = { ["2v2"] = "2 CONTRO 2", ["1v1"] = "1 CONTRO 1", torneo = "TORNEO", campagna = "CAMPAGNA",
	ffa = "TUTTI CONTRO TUTTI", tutte = "TUTTE" }
-- le partite che si tengono (coi replay di quelle giocate su questo telefono)
M.PARTITE = 10

-- I valori di un gruppo ({} se non c'è); "tutte" li somma
function M.statistiche(p, gruppo)
	if gruppo ~= "tutte" then return p.statistiche[gruppo] or {} end
	local tot = {}
	for _, g in pairs(p.statistiche) do
		for k, v in pairs(g) do
			if type(v) == "number" then
				local s = traguardi.BY_ID[k]
				if (s and s.record) or k == "serie" then
					tot[k] = math.max(tot[k] or 0, v)
				else
					tot[k] = (tot[k] or 0) + v
				end
			elseif type(v) == "table" then
				-- il danno per arma
				tot[k] = tot[k] or {}
				for w, n in pairs(v) do tot[k][w] = (tot[k][w] or 0) + n end
			end
		end
	end
	return tot
end

-- I badge accanto al nome: quelli scelti, poi i più alti (menu/traguardi.lua)
function M.badge(p)
	return traguardi.mostrati(M.statistiche(p, "tutte"), p.badge)
end

-- Tocca un badge nella scheda: se è fra quelli scelti si toglie, sennò si
-- mette davanti (al massimo traguardi.MOSTRATI)
function M.scegli_badge(p, id)
	for i, b in ipairs(p.badge) do
		if b == id then
			table.remove(p.badge, i)
			return false
		end
	end
	table.insert(p.badge, 1, id)
	while #p.badge > traguardi.MOSTRATI do table.remove(p.badge) end
	return true
end

-- Fine partita: r è il riassunto di menu/conta.lua (gruppo, valori, armi,
-- vinta, partita). Somma le statistiche nel gruppo, tiene la serie di vittorie
-- e mette la partita in cima alla lista (le più vecchie escono). Restituisce
-- la partita salvata, col suo numero (per il file del replay).
function M.registra(p, r)
	local g = p.statistiche[r.gruppo] or {}
	p.statistiche[r.gruppo] = g
	for k, v in pairs(r.valori) do
		local s = traguardi.BY_ID[k]
		if s and s.record then g[k] = math.max(g[k] or 0, v) else g[k] = (g[k] or 0) + v end
	end
	g.partite = (g.partite or 0) + 1
	if r.vinta then
		g.vinte = (g.vinte or 0) + 1
		p.serie = p.serie + 1
	elseif r.vinta == false then
		p.serie = 0
	end
	g.serie = math.max(g.serie or 0, p.serie)
	g.armi = g.armi or {}
	for w, n in pairs(r.armi or {}) do g.armi[w] = (g.armi[w] or 0) + n end
	p.numero = p.numero + 1
	local partita = r.partita
	partita.numero = p.numero
	table.insert(p.partite, 1, partita)
	while #p.partite > M.PARTITE do table.remove(p.partite) end
	return partita
end

-- Solo negli scenari (imposta prova_profilo 1, scenari/scheda.txt): un profilo
-- che ha già giocato, per vedere pezzi, poteri, badge e statistiche
function M.prova(p)
	p.livello, p.xp = 23, 410
	local a = p.assetti[p.attivo]
	a.gear = { mask = "corvo", chest = "fornace", cloak = "corvo", legs = "leviatano" }
	a.tree = { jump = 2, walk = 1, air_jump = 1, hp = 1, teleport = 1, trap_wide = 2 }
	p.maestria.corvo_mask, p.maestria.fornace_chest, p.maestria.corvo_cloak, p.maestria.leviatano_legs = 24, 18, 11, 6
	p.statistiche["2v2"] = { partite = 48, vinte = 27, colpi = 310, a_segno = 190, danno = 14500, abbattuti = 60,
		nel_vuoto = 23, globi = 140, colpo_lungo = 1180, casse = 35, cadute = 12, morti = 30, serie = 4,
		armi = { missile = 5200, grenade = 3100, eagle = 2600, sword = 1800, mallet = 1300, shards = 500 } }
	p.statistiche["1v1"] = { partite = 9, vinte = 4, colpi = 60, a_segno = 31, danno = 2100, abbattuti = 8, globi = 20,
		colpo_lungo = 700, casse = 6, serie = 2, armi = { missile = 1200, sniper = 900 } }
	p.serie, p.badge = 1, { "colpo_lungo" }
end

-- Il file del replay di una partita: uno per posto, si riusano a giro
function M.posto_replay(numero)
	return (numero - 1) % M.PARTITE + 1
end

-- Missioni della campagna e lezioni (sim/campagna.lua): per ognuna le tre
-- stelle { true, false, true }, ognuna presa una volta resta (anche in
-- partite diverse)
function M.missione(p, id, stelle)
	local prese = p.stelle[id] or { false, false, false }
	for i = 1, 3 do prese[i] = prese[i] or stelle[i] == true end
	p.stelle[id] = prese
	p.fallite[id] = nil
end

-- Una missione persa: dalla terza di fila gli avversari si danno una calmata
-- (sim/missioni.lua, aiuto), senza dirlo
M.AIUTO_DOPO = 3
function M.fallita(p, id)
	p.fallite[id] = (p.fallite[id] or 0) + 1
end

function M.aiuto(p, id)
	return (p.fallite[id] or 0) >= M.AIUTO_DOPO
end

-- Tutte le stelle prese (aprono i capitoli della campagna)
function M.stelle_totali(p)
	local n = 0
	for _, v in pairs(p.stelle) do
		for i = 1, 3 do
			if v[i] then n = n + 1 end
		end
	end
	return n
end

-- Le basi dell'Addestramento (sim/campagna.lua): chi non le ha finite tutte
-- è un giocatore nuovo, e GIOCA lo porta alla prima che manca (Claude, 29 ott:
-- prima la Prima partita, che ora è l'esame finale del capitolo). Oggi sono un
-- percorso solo, Primi passi (Sergio, 29 ott)
local BASI = { "primi_passi" }

function M.prima_lezione(p)
	for _, id in ipairs(BASI) do
		if not (p.stelle[id] and p.stelle[id][1]) then return id end
	end
	return nil
end

function M.nuovo_giocatore(p)
	return M.prima_lezione(p) ~= nil
end

-- Un'arma trovata (battaglia/scheda.lua): vero solo la prima volta, poi resta
-- vista (la sua scheda non esce più fuori dalle lezioni)
function M.arma_nuova(p, w)
	if p.armi[w] then return false end
	p.armi[w] = true
	return true
end

-- Le armi che il giocatore ha già visto: quelle trovate nelle casse e quelle
-- che le missioni finite gli hanno dato. La scelta delle armi della campagna
-- offre solo queste (Sergio, 30 ott)
function M.armi_viste(p)
	local viste = {}
	for w in pairs(p.armi) do viste[w] = true end
	for _, cap in ipairs(require("sim.campagna").CAPITOLI) do
		for _, l in ipairs(cap.missioni) do
			local mio = l.giocatori and l.giocatori[1]
			if mio and p.stelle[l.id] and p.stelle[l.id][1] then
				for _, w in ipairs({ mio.pick or "", mio.secondary or "" }) do viste[w] = true end
			end
		end
	end
	return viste
end

-- Salvataggio --------------------------------------------------------------------

local function file()
	return sys.get_save_file("megablast", "profilo")
end

function M.carica()
	local ok, p = pcall(sys.load, file())
	if not ok or type(p) ~= "table" or p.versione ~= M.VERSIONE then return M.nuovo() end
	-- i profili salvati prima della campagna tenevano le stelle delle lezioni in p.lezioni
	p.stelle = p.stelle or p.lezioni or {}
	p.lezioni = nil
	-- prima le stelle erano un numero: le prime n
	for id, v in pairs(p.stelle) do
		if type(v) == "number" then p.stelle[id] = { v >= 1, v >= 2, v >= 3 } end
	end
	p.fallite = p.fallite or {}
	p.armi = p.armi or {}
	p.statistiche, p.partite, p.badge = p.statistiche or {}, p.partite or {}, p.badge or {}
	p.serie, p.numero = p.serie or 0, p.numero or 0
	return p
end

function M.salva(p)
	sys.save(file(), p)
end

return M
