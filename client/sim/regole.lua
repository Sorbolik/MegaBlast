-- Regole come dati (Sergio, 31 ottobre 2026): quello che un evento può
-- cambiare della partita, scritto come valori e mai come codice. La lista
-- bianca è qui: il server rifiuta un evento con una chiave che non c'è o un
-- valore fuori dai limiti, e client e server passano le stesse regole a
-- game.new e alla scelta delle armi, così la partita è identica sui due lati.
-- Proposta: https://claude.ai/artifact/WhmGJpMT4hfsD2MdPfHpUC
--
--   local regole = require "sim.regole"
--   local ok, err = regole.valida(r)        -- r = { casse = 2, armi = { "punch", "mallet" }, ... }
--   regole.opzioni(r, opts)                 -- aggiunge a opts di game.new
--   local viste = regole.armi(r)            -- armi offerte nella scelta (sim/draft.lua), o nil
--
-- Una regola nuova si aggiunge qui (con i suoi limiti) e in opzioni; se serve
-- una cosa che game.new non sa ancora fare, prima va insegnata alla simulazione.

local C = require "sim.config"
local game = require "sim.game"

local M = {}

local PRIMARIE, SECONDARIE = {}, {}
for _, w in ipairs(game.CRATE_WEAPONS) do PRIMARIE[w] = true end
for _, w in ipairs(game.DRAFT_SECONDARIES) do SECONDARIE[w] = true end

-- un numero intero fra a e b
local function intero(a, b)
	return function(v)
		return type(v) == "number" and v == math.floor(v) and v >= a and v <= b, "da " .. a .. " a " .. b
	end
end

-- La lista bianca: chiave -> controllo del valore (vero, o falso e il perché)
M.LISTA = {
	-- turni fra una cassa e l'altra (la prima cade sempre al primo turno)
	casse = intero(1, 10),
	-- false: niente cerchi di cura
	cure = function(v) return type(v) == "boolean", "vero o falso" end,
	-- "fisso": albero ed equipaggiamento non contano, tutti hanno le statistiche di base
	livello = function(v) return v == "fisso", "solo \"fisso\"" end,
	-- le armi della scelta d'inizio partita: almeno una primaria e una secondaria
	-- (Lanciarune e Lama restano sempre)
	armi = function(v)
		if type(v) ~= "table" or #v == 0 then return false, "una lista di armi" end
		local p, s = false, false
		for _, w in ipairs(v) do
			if PRIMARIE[w] then p = true elseif SECONDARIE[w] then s = true
			else return false, "arma sconosciuta: " .. tostring(w) end
		end
		return p and s, "almeno una primaria e una secondaria"
	end,
	-- punti partita diversi da config.SCORE, solo i campi che cambiano
	punti = function(v)
		if type(v) ~= "table" then return false, "una tabella di punti" end
		for k, n in pairs(v) do
			if C.SCORE[k] == nil then return false, "punto sconosciuto: " .. tostring(k) end
			if type(n) ~= "number" or n < -1000 or n > 1000 then return false, k .. " da -1000 a 1000" end
		end
		return true
	end,
}

function M.valida(r)
	if type(r) ~= "table" then return nil, "le regole sono una tabella" end
	for k, v in pairs(r) do
		local controllo = M.LISTA[k]
		if not controllo then return nil, "regola sconosciuta: " .. tostring(k) end
		local ok, perche = controllo(v)
		if not ok then return nil, k .. ": " .. perche end
	end
	return true
end

function M.opzioni(r, opts)
	if not r then return opts end
	if r.casse then opts.crate_every = r.casse end
	if r.cure == false then opts.heals = false end
	if r.livello == "fisso" then opts.normalize = true end
	if r.punti then opts.score = r.punti end
	return opts
end

function M.armi(r)
	if not (r and r.armi) then return nil end
	local viste = {}
	for _, w in ipairs(r.armi) do viste[w] = true end
	return viste
end

return M
