-- Profilo del giocatore sul telefono: livello, maestria dei pezzi e i 3
-- assetti. Finché il server non tiene gli account si salva in locale (sys.save); la logica è Lua puro e si prova nei test.
--
-- Progressione (docs/game_design_competitivo.md, "Più avanti: reward e
-- progressione"): ogni partita dà esperienza (anche persa, di più sul podio);
-- il livello dà i punti dell'albero; giocare con un pezzo ne alza il tier.
-- Le Scorie (materiale della Forgia) arriveranno con la Forgia.

local abilita = require "sim.abilita"
local assetto = require "sim.assetto"
local equip = require "sim.equipaggiamento"

local M = {}

M.VERSIONE = 1
-- esperienza per posto (1°, 2°, 3°, 4°) e per ogni riconoscimento
M.XP_POSTO = { 120, 80, 60, 50 }
M.XP_RICONOSCIMENTO = 25
-- esperienza per passare dal livello n al n + 1: XP_BASE + XP_PASSO * (n - 1)
M.XP_BASE, M.XP_PASSO = 100, 25

function M.nuovo()
	local p = { versione = M.VERSIONE, xp = 0, livello = 1, maestria = {}, assetti = {}, attivo = 1, stelle = {}, fallite = {} }
	for i = 1, assetto.LOADOUTS do p.assetti[i] = assetto.new() end
	return p
end

-- esperienza che serve per salire dal livello n
function M.xp_livello(n)
	return M.XP_BASE + M.XP_PASSO * (n - 1)
end

function M.punti(p, torneo)
	return abilita.points(p.livello, torneo)
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

-- Missioni della campagna e lezioni (sim/campagna.lua): le stelle migliori di ognuna, 0..3
function M.missione(p, id, stelle)
	p.stelle[id] = math.max(p.stelle[id] or 0, stelle)
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
	for _, v in pairs(p.stelle) do n = n + v end
	return n
end

-- Chi non ha mai finito la prima partita guidata: GIOCA lo porta lì
function M.nuovo_giocatore(p)
	return (p.stelle.guidata or 0) == 0
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
	p.fallite = p.fallite or {}
	return p
end

function M.salva(p)
	sys.save(file(), p)
end

return M
