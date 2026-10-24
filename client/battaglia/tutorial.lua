-- Tutorial a passi (docs/game_design_competitivo.md, "Insegnare il turno"): una
-- regola nuova per volta, ognuna in una mini-missione con un bersaglio che non
-- gioca. Lua puro: niente nodi, il gui_script mostra titolo e consiglio.
--
--   local t = tutorial.new()
--   local g = tutorial.partita(t, seed)      -- la partita del passo corrente, oppure:
--   g = game.new(seed, tutorial.MAPPA, tutorial.opzioni(t)); tutorial.prepara(t, g)
--   tutorial.evento(t, g, e)                 -- per ogni evento della simulazione
--   if tutorial.fatto(t, g) then ... end     -- a ogni tick: obiettivo raggiunto?
--   tutorial.avanti(t)                       -- passo dopo (false: era l'ultimo)
--   local p = tutorial.passo(t)              -- { titolo, consiglio }

local game = require "sim.game"

local M = {}

local GIOCATORE, BERSAGLIO = 1, 2

-- Ogni passo: dove sta il bersaglio rispetto al giocatore (dx in pixel), le
-- statistiche del giocatore, e quando l'obiettivo è raggiunto (st è la
-- memoria del passo, e un evento o nil).
M.PASSI = {
	{
		titolo = "1. Muoviti e spara",
		consiglio = "Cammina, poi tieni premuto, mira e lascia: parte il missile.",
		dx = 320,
		obiettivo = function(st, g, e)
			local rb = g.robots[GIOCATORE]
			st.x0 = st.x0 or rb.x
			if math.abs(rb.x - st.x0) >= 30 then st.mosso = true end
			if e and e.type == "fire" then st.sparato = true end
			return st.mosso and st.sparato
		end,
	},
	{
		titolo = "2. Riparati",
		consiglio = "Spara: dopo il colpo hai 8 secondi (la barra gialla) per spostarti. Mettiti al riparo.",
		dx = 320,
		obiettivo = function(st, g)
			local rb = g.robots[GIOCATORE]
			if g.window <= 0 then return false end
			st.x0 = st.x0 or rb.x
			return math.abs(rb.x - st.x0) >= 30
		end,
	},
	{
		titolo = "3. La spada",
		consiglio = "Il bersaglio ti sta vicino: scegli la Lama di Nucleo e colpiscilo.",
		dx = 34,
		obiettivo = function(_, _, e)
			return e ~= nil and e.type == "sword_hit" and e.target == BERSAGLIO
		end,
	},
	{
		titolo = "4. Due attacchi",
		consiglio = "Spara e colpisci con la spada: con la barra gialla hai ancora il secondo attacco, con quella blu li hai usati tutti e due.",
		dx = 60,
		obiettivo = function(_, g)
			return g.used.primary and g.used.secondary
		end,
	},
	{
		titolo = "5. Nucleo e teletrasporto",
		consiglio = "Spara subito: i secondi rimasti diventano Nucleo. Poi spendilo per lanciare il teletrasporto (T).",
		dx = 320,
		stats = { start_nucleo = 0 },
		obiettivo = function(st, _, e)
			if e and e.type == "nucleo" and e.robot == GIOCATORE then st.nucleo = true end
			return st.nucleo and e ~= nil and e.type == "teleport" and e.robot == GIOCATORE
		end,
	},
	{
		titolo = "6. La combo",
		consiglio = "Lancia il teletrasporto oltre il bersaglio e chiudi col fendente appena arrivi.",
		dx = 200,
		stats = { start_nucleo = 2 },
		obiettivo = function(st, g, e)
			if not e then return false end
			if e.type == "teleport" and e.robot == GIOCATORE then st.arrivo = g.tick end
			return e.type == "sword_hit" and e.target == BERSAGLIO and st.arrivo ~= nil and g.tick - st.arrivo <= 120
		end,
	},
}

function M.new()
	return { n = 1, st = {} }
end

function M.passo(t)
	return M.PASSI[t.n]
end

M.MAPPA = "forgia"

-- La partita del passo: il giocatore e un bersaglio che non gioca (niente casse)
function M.opzioni(t)
	return { players = { { team = 1, stats = M.PASSI[t.n].stats }, { team = 2, dummy = true } }, crate_every = 1000 }
end

-- Il bersaglio a dx pixel dal giocatore, sul terreno
function M.prepara(t, g)
	local p = M.PASSI[t.n]
	t.st, t.ok = {}, nil
	local me, bersaglio = g.robots[GIOCATORE], g.robots[BERSAGLIO]
	local x = math.max(40, math.min(game.WORLD_W - 40, me.x + p.dx))
	bersaglio.x = x
	bersaglio.y = g.terrain:ground_below(x, me.y + 80) or me.y
	bersaglio.facing = -1
end

function M.partita(t, seed)
	local g = game.new(seed, M.MAPPA, M.opzioni(t))
	M.prepara(t, g)
	g:pop_events()
	return g
end

function M.evento(t, g, e)
	if M.PASSI[t.n].obiettivo(t.st, g, e) then t.ok = true end
end

-- Controllo a ogni tick (gli obiettivi sullo stato, come lo spostamento)
function M.fatto(t, g)
	if not t.ok and M.PASSI[t.n].obiettivo(t.st, g, nil) then t.ok = true end
	return t.ok == true
end

function M.avanti(t)
	if t.n >= #M.PASSI then return false end
	t.n = t.n + 1
	return true
end

return M
