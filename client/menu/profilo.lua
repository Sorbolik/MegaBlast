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
	local p = { versione = M.VERSIONE, xp = 0, livello = 1, maestria = {}, assetti = {}, attivo = 1 }
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

-- Salvataggio --------------------------------------------------------------------

local function file()
	return sys.get_save_file("megablast", "profilo")
end

function M.carica()
	local ok, p = pcall(sys.load, file())
	if not ok or type(p) ~= "table" or p.versione ~= M.VERSIONE then return M.nuovo() end
	return p
end

function M.salva(p)
	sys.save(file(), p)
end

return M
