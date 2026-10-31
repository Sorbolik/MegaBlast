-- Conta le statistiche di chi gioca su questo telefono durante la partita, e a
-- fine partita ne fa il riassunto per il profilo (profilo.registra): i numeri
-- delle statistiche, il danno per arma, e la partita per la scheda PARTITE
-- (com'è andata giro per giro, i momenti da rivedere, chi c'era). Lua puro:
-- guarda gli eventi della simulazione e lo stato, uguale in locale e online.
--
--   local c = conta.nuova(g, me, nomi)       -- me: il robot di chi gioca qui
--   conta.sparo(c, g, arma)                  -- quando me attacca
--   conta.evento(c, g, e)                    -- per ogni evento della sim
--   conta.tick(c, g)                         -- dopo ogni passo (i giri)
--   local r = conta.fine(c, g, results, info) -- info: gruppo, mappa, quando, giocatori

local M = {}

-- da quanti pixel un colpo diventa un momento della partita
M.LUNGO = 900
-- i momenti che si tengono
M.MOMENTI = 8

local function punti_squadre(g)
	local t = {}
	for _, rb in ipairs(g.robots) do t[rb.team] = (t[rb.team] or 0) + rb.points end
	return t
end

-- i punti della mia squadra meno quelli della migliore delle altre
local function vantaggio(c, g)
	local t = punti_squadre(g)
	local mio, altro = t[c.team] or 0, nil
	for team, v in pairs(t) do
		if team ~= c.team and (not altro or v > altro) then altro = v end
	end
	return math.floor(mio - (altro or 0) + 0.5), math.floor(mio + 0.5), math.floor((altro or 0) + 0.5)
end

function M.nuova(g, me, nomi)
	local c = { me = me, team = g.robots[me].team, nomi = nomi or {}, armi = {}, momenti = {},
		fune = { 0 }, giro = g.round or 1,
		colpi = 0, a_segno = 0, globi = 0, colpo_lungo = 0 }
	return c
end

local function giro(c, g)
	return g.final_round and "finale" or ("giro " .. (g.round or 1))
end

local function momento(c, g, testo)
	if #c.momenti >= M.MOMENTI then return end
	c.momenti[#c.momenti + 1] = { t = g.tick, giro = giro(c, g), testo = testo }
end

-- Il robot me attacca con arma (anche lo scambio con un globo, che non conta)
function M.sparo(c, g, arma)
	if arma == "swap" or arma == "teleport" then return end
	local rb = g.robots[c.me]
	c.arma = arma
	c.colpi = c.colpi + 1
	c.colpo = { x = rb.x, y = rb.y, preso = false }
end

local function nemico(c, g, i)
	local rb = g.robots[i]
	return rb and rb.team ~= c.team
end

function M.evento(c, g, e)
	local t = e.type
	if t == "damage" and e.by == c.me and nemico(c, g, e.robot) and c.colpo then
		-- real: la vita tolta davvero (come il danno della classifica)
		c.armi[c.arma] = (c.armi[c.arma] or 0) + (e.real or e.amount or 0)
		if not c.colpo.preso then
			c.colpo.preso = true
			c.a_segno = c.a_segno + 1
			local o = g.robots[e.robot]
			local d = math.floor(math.sqrt((o.x - c.colpo.x) ^ 2 + (o.y - c.colpo.y) ^ 2) + 0.5)
			if d > c.colpo_lungo then c.colpo_lungo = d end
			if d >= M.LUNGO then
				momento(c, g, string.format("Colpo da %d px su %s", d, c.nomi[e.robot] or "?"))
			end
		end
	elseif t == "death" then
		if e.by == c.me and nemico(c, g, e.robot) then
			momento(c, g, (e.env and "Butti nel vuoto " or "Abbatti ") .. (c.nomi[e.robot] or "?"))
		elseif e.robot == c.me and e.by and nemico(c, g, e.by) then
			momento(c, g, (c.nomi[e.by] or "?") .. (e.env and " ti butta nel vuoto" or " ti abbatte"))
		end
	elseif (t == "teleports" or t == "swap") and e.robot == c.me then
		c.globi = c.globi + (t == "swap" and 1 or (e.amount or 0))
	elseif t == "final_round" then
		momento(c, g, "Ultimo giro a punti doppi")
	elseif t == "turn" then
		c.colpo = nil
	end
end

-- Dopo ogni passo: a ogni giro nuovo il vantaggio sulla fune
function M.tick(c, g)
	local r = g.round or 1
	if r ~= c.giro then
		c.giro = r
		c.fune[#c.fune + 1] = (vantaggio(c, g))
	end
end

-- Il riassunto per profilo.registra. info: gruppo (2v2, 1v1, torneo,
-- campagna...), mappa (il nome), quando (os.time()), giocatori ({ nome,
-- squadra, vetrina } per robot)
function M.fine(c, g, results, info)
	local mia
	for _, v in ipairs(results.ranking) do
		if v.robot == c.me then mia = v end
	end
	mia = mia or {}
	local diff, mio, altro = vantaggio(c, g)
	c.fune[#c.fune + 1] = diff
	local vinta = nil
	if results.winner then vinta = results.winner == c.team end
	local valori = {
		colpi = c.colpi, a_segno = c.a_segno, globi = c.globi, colpo_lungo = c.colpo_lungo,
		danno = mia.damage or 0, abbattuti = mia.kills or 0, nel_vuoto = mia.env_kills or 0,
		cadute = mia.falls or 0, morti = mia.deaths or 0, casse = mia.crates or 0,
		teletrasporti = mia.teleports or 0,
	}
	local armi = {}
	for w, n in pairs(c.armi) do armi[w] = math.floor(n + 0.5) end
	return {
		gruppo = info.gruppo, valori = valori, armi = armi, vinta = vinta,
		partita = {
			quando = info.quando, gruppo = info.gruppo, modo = results.mode, mappa = info.mappa,
			esito = vinta == true and "V" or vinta == false and "S" or "P",
			punti = { mio, altro }, fune = c.fune, momenti = c.momenti,
			giocatori = info.giocatori, me = c.me,
		},
	}
end

return M
