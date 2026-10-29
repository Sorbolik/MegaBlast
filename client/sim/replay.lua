-- Ricetta di una partita: i pochi dati che bastano a rigiocarla identica
-- (la simulazione è deterministica). Seme, mappa, opzioni di game.new (coi
-- giocatori, e per i bot il livello), i tasti dei giocatori veri solo quando
-- cambiano, e le impronte dello stato (game:impronta) ogni OGNI tick e alla
-- fine: chi la rigioca deve ritrovarle tutte uguali, altrimenti la partita non
-- è valida (versione diversa, codice cambiato, dati toccati).
-- Serve all'arena dei bot (strumenti/arena), ai replay e ai controlli del server.
--
--   local replay = require "sim.replay"
--   local r = replay.nuova(seme, mappa, opts)    -- opts come game.new; players[i].bot = "normale" per un bot
--   local g, bots = replay.partita(r)
--   ogni tick:
--     local input = replay.input(r, g, bots, input_del_giocatore)
--     g:step(input)
--     replay.dopo(r, g)
--   local ok, tick = replay.verifica(r)          -- la rigioca: true, o false e il tick dove diverge

local game = require "sim.game"
local bot = require "sim.bot"

local M = {}

M.VERSIONE = 1
-- ogni quanti tick si prende l'impronta (10 s)
M.OGNI = 600

local function copia(t)
	if type(t) ~= "table" then return t end
	local o = {}
	for k, v in pairs(t) do o[k] = copia(v) end
	return o
end

function M.nuova(seme, mappa, opts)
	return { versione = M.VERSIONE, fisica = game.PHYSICS, seme = seme, mappa = mappa,
		opzioni = copia(opts or {}), input = {}, impronte = {} }
end

-- La partita e i bot della ricetta, all'inizio
function M.partita(r)
	assert(r.fisica == game.PHYSICS, "la ricetta è per la fisica " .. tostring(r.fisica))
	local g = game.new(r.seme, r.mappa, copia(r.opzioni))
	local bots = {}
	for i, p in ipairs(r.opzioni.players or {}) do
		if p.bot then bots[i] = bot.new(i, p.bot, r.seme) end
	end
	r.ultimo = nil
	return g, bots
end

local function uguali(a, b)
	return (a.left or false) == (b.left or false) and (a.right or false) == (b.right or false)
		and (a.jump or false) == (b.jump or false) and a.hold == b.hold
end

-- L'input del tick: del bot se tocca a un bot, altrimenti quello del
-- giocatore, che si scrive nella ricetta (solo i cambiamenti e i colpi)
function M.input(r, g, bots, umano)
	local b = bots[g.current]
	if b then return bot.input(b, g) end
	umano = umano or {}
	local prima = r.ultimo or {}
	if umano.fire or not uguali(umano, prima) then
		local f = umano.fire
		r.input[#r.input + 1] = { t = g.tick + 1, l = umano.left or false, r = umano.right or false,
			j = umano.jump or false, h = umano.hold,
			f = f and { w = f.weapon, a = f.angle, p = f.power } or nil }
	end
	r.ultimo = umano
	return umano
end

-- Dopo g:step: l'impronta, ogni OGNI tick e alla fine
function M.dopo(r, g)
	if g.tick % M.OGNI == 0 or g.phase == "over" then
		r.impronte[#r.impronte + 1] = { t = g.tick, h = g:impronta() }
	end
end

-- Rigioca la ricetta e confronta le impronte. Restituisce true, o false e il
-- tick della prima impronta diversa (o mancante).
function M.verifica(r, max_tick)
	local g, bots = M.partita(r)
	local k, cur = 1, {}
	local n = 1
	local attese = r.impronte
	max_tick = max_tick or (attese[#attese] and attese[#attese].t) or 0
	while g.phase ~= "over" and g.tick < max_tick do
		local input
		local b = bots[g.current]
		if b then
			input = bot.input(b, g)
		else
			local e = r.input[k]
			while e and e.t == g.tick + 1 do
				cur = { left = e.l, right = e.r, jump = e.j, hold = e.h,
					fire = e.f and { weapon = e.f.w, angle = e.f.a, power = e.f.p } or nil }
				k = k + 1
				e = r.input[k]
			end
			input = cur
		end
		g:step(input)
		-- il colpo vale per un tick solo
		if cur.fire then cur = { left = cur.left, right = cur.right, jump = cur.jump, hold = cur.hold } end
		local a = attese[n]
		if a and a.t == g.tick then
			if a.h ~= g:impronta() then return false, g.tick end
			n = n + 1
		end
	end
	if attese[n] then return false, attese[n].t end
	return true
end

return M
