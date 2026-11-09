-- I dati del gioco che servono al pannello degli eventi (armi, punti, code,
-- limiti delle regole), presi dalla simulazione così il pannello controlla
-- un evento come il server. Da rifare quando cambiano armi, punti o regole:
--
--   luajit strumenti/eventi/dati.lua      (dalla radice del repository)
--
-- Scrive strumenti/eventi/pagina/dati.json; go test ./server/ controlla che sia
-- in pari con la simulazione (TestPanelData).
package.path = "client/?.lua;" .. package.path
local C = require "sim.config"
local game = require "sim.game"
local equip = require "sim.gear"
local regole = require "sim.rules"

-- i nomi delle armi come li vede il giocatore: client/lang/it.lua (hud.weapons)
local nomi = require("lang.it").hud.weapons

local function chiavi(t)
	local k = {}
	for n in pairs(t) do k[#k + 1] = n end
	table.sort(k)
	return k
end

local modi = {}
for _, m in ipairs(chiavi(C.MODES)) do modi[m] = #C.MODES[m] end
local sempre = {}
for _, w in ipairs(chiavi(game.FREE_WEAPONS)) do
	if w ~= "teleport" then sempre[#sempre + 1] = w end
end

local dati = {
	primarie = game.CRATE_WEAPONS,
	secondarie = game.DRAFT_SECONDARIES,
	sempre = sempre,
	nomi = nomi,
	punti = C.SCORE,
	casse = game.CRATE_EVERY,
	tetto_max = equip.LIVELLO_MAX - 1,
	modi = modi,
	coda_normale = chiavi(regole.CODA_NORMALE),
}

-- JSON con le chiavi in ordine, così il file cambia solo quando cambiano i dati
local function json(v, rientro)
	rientro = rientro or ""
	if type(v) == "string" then return string.format("%q", v) end
	if type(v) ~= "table" then return tostring(v) end
	local dentro, out = rientro .. "\t", {}
	if #v > 0 then
		for _, x in ipairs(v) do out[#out + 1] = json(x, dentro) end
		return "[" .. table.concat(out, ", ") .. "]"
	end
	for _, k in ipairs(chiavi(v)) do out[#out + 1] = dentro .. string.format("%q", k) .. ": " .. json(v[k], dentro) end
	return "{\n" .. table.concat(out, ",\n") .. "\n" .. rientro .. "}"
end

local f = assert(io.open("strumenti/eventi/pagina/dati.json", "w"))
f:write(json(dati), "\n")
f:close()
print("strumenti/eventi/pagina/dati.json")
