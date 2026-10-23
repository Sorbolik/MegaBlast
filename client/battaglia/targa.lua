-- La targa sopra la Scoria in battaglia: il nome e una barra della vita sottile,
-- solo forme semplici disegnate dal codice (nessuna immagine), nel colore della
-- squadra. Il danno si vede in due tempi: la vita scende subito, il pezzo perso
-- resta bianco un attimo e poi si consuma; la barra sobbalza e lampeggia. Sotto
-- il 30% la vita pulsa. Lo scudo, se c'è, è un tratto chiaro dopo la vita.
--
--   local tt = targa.nuove(colori, nomi)  -- una targa per colore, tutte insieme
--   targa.vita(t, vita, massima, scudo)   -- quando cambia (scudo può mancare)
--   targa.update(t, dt, x, y, scala)      -- a ogni frame: x, y è il centro in basso
--   targa.set_enabled(t, on) / targa.nome(t, nome)
--
-- Ogni targa ha due radici, t.barre e t.testi, che si muovono insieme. La GUI
-- disegna i nodi nell'ordine in cui stanno: chi le mette nella scena mette prima
-- le barre di tutte le targhe e poi tutti i testi, così bastano due draw call per
-- tutte (forme senza immagine, poi il font). Non usiamo i layer della GUI perché
-- disegnerebbero le targhe sopra i pulsanti e i menu.

local M = {}

local max = math.max

-- misure in unità della GUI con scala 1
local W, H = 44, 4          -- la barra
local BORDO = 1             -- il fondo scuro attorno
local NOME_Y = 10           -- centro del nome sopra la barra
local NOME_SCALA, NUMERO_SCALA = 0.62, 0.5

local FONDO = vmath.vector4(0.03, 0.03, 0.04, 0.7)
local SCURO = vmath.vector4(0.03, 0.03, 0.04, 1)
local SCIA = vmath.vector4(1, 1, 1, 0.9)
local SCUDO = vmath.vector4(0.75, 0.86, 1, 1)
local BIANCO = vmath.vector4(1, 1, 1, 1)

local V = vmath.vector3(0, 0, 0)
local C = vmath.vector4(1, 1, 1, 1)

local function rettangolo(parent, x, y, w, h, colore)
	local n = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(w, h, 0))
	gui.set_parent(n, parent)
	gui.set_inherit_alpha(n, true)
	gui.set_color(n, colore)
	return n
end

local function testo(parent, x, y, s, scala, colore)
	local n = gui.new_text_node(vmath.vector3(x, y, 0), s)
	gui.set_parent(n, parent)
	gui.set_inherit_alpha(n, true)
	gui.set_font(n, "default")
	gui.set_color(n, colore)
	gui.set_outline(n, SCURO)
	gui.set_scale(n, vmath.vector3(scala, scala, 1))
	return n
end

-- un pezzo della barra: parte dal bordo sinistro, largo w (da x)
local function pezzo(t, colore)
	local n = rettangolo(t.dentro, -W / 2, 0, 0, H, colore)
	gui.set_pivot(n, gui.PIVOT_W)
	return n
end

local function larghezza(n, x, w)
	gui.set_enabled(n, w > 0.05)
	V.x, V.y, V.z = -W / 2 + x, 0, 0
	gui.set_position(n, V)
	V.x, V.y = w, H
	gui.set_size(n, V)
end

-- un nodo radice invisibile che segue la Scoria, con dentro il nodo che sobbalza
local function radice()
	local r = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(r, false)
	gui.set_adjust_mode(r, gui.ADJUST_STRETCH)
	local d = rettangolo(r, 0, H / 2 + BORDO, 0, 0, FONDO)
	gui.set_visible(d, false)
	return r, d
end

function M.nuove(colori, nomi)
	local tt = {}
	-- prima le barre di tutte le targhe
	for i, colore in ipairs(colori) do
		local t = { colore = vmath.vector4(colore.x, colore.y, colore.z, 1), vita_f = 1, scia_f = 1,
			scudo_f = 0, max_f = 1, attesa = 0, colpo = 0, t = 0 }
		t.barre, t.dentro = radice()
		rettangolo(t.dentro, 0, 0, W + 2 * BORDO, H + 2 * BORDO, FONDO)
		t.scia = pezzo(t, SCIA)
		t.scudo = pezzo(t, SCUDO)
		t.pieno = pezzo(t, colore)
		tt[i] = t
	end
	-- poi i testi
	for i, t in ipairs(tt) do
		t.testi, t.dentro_testi = radice()
		t.nome = testo(t.dentro_testi, 0, NOME_Y, nomi[i] or "", NOME_SCALA, t.colore)
		t.numero = testo(t.dentro_testi, W / 2 + BORDO + 3, 0, "", NUMERO_SCALA, BIANCO)
		gui.set_pivot(t.numero, gui.PIVOT_W)
		M.vita(t, 1, 1)
	end
	return tt
end

function M.nome(t, nome)
	gui.set_text(t.nome, nome)
end

function M.set_enabled(t, on)
	gui.set_enabled(t.barre, on)
	gui.set_enabled(t.testi, on)
end

-- vita e scudo in punti; la barra conta fino a massima, o a vita + scudo se di più
function M.vita(t, vita, massima, scudo)
	vita, scudo = max(0, vita), max(0, scudo or 0)
	local tot = max(massima, vita + scudo)
	local f = vita / tot
	if f < t.vita_f - 1e-6 then
		-- colpo: la scia parte da dove era la vita (se non era già più su)
		t.scia_f = max(t.scia_f, t.vita_f)
		t.attesa = 0.45
		t.colpo = 1
	elseif f > t.scia_f then
		t.scia_f = f
	end
	t.vita_f, t.scudo_f, t.max_f = f, scudo / tot, massima / tot
	gui.set_text(t.numero, tostring(math.floor(vita + 0.5)))
end

function M.update(t, dt, x, y, scala)
	t.t = t.t + dt
	V.x, V.y, V.z = x, y, 0
	gui.set_position(t.barre, V)
	gui.set_position(t.testi, V)
	V.x, V.y, V.z = scala, scala, 1
	gui.set_scale(t.barre, V)
	gui.set_scale(t.testi, V)

	-- la scia aspetta un attimo e poi si consuma fino alla vita
	if t.attesa > 0 then
		t.attesa = t.attesa - dt
	elseif t.scia_f > t.vita_f then
		t.scia_f = max(t.vita_f, t.scia_f - dt * 0.9)
	end
	-- sobbalzo del colpo
	t.colpo = max(0, t.colpo - dt * 5)
	local k = 1 + 0.25 * t.colpo
	V.x, V.y, V.z = k, k, 1
	gui.set_scale(t.dentro, V)
	gui.set_scale(t.dentro_testi, V)

	larghezza(t.scia, 0, W * t.scia_f)
	larghezza(t.pieno, 0, W * t.vita_f)
	larghezza(t.scudo, W * t.vita_f, W * t.scudo_f)

	-- colore della vita: bianco nel colpo, pulsa quando è bassa
	local bianco = t.colpo
	if t.vita_f > 0 and t.vita_f < 0.3 * t.max_f then
		bianco = max(bianco, 0.3 + 0.3 * math.sin(t.t * 9))
	end
	local c = t.colore
	C.x, C.y, C.z, C.w = c.x + (1 - c.x) * bianco, c.y + (1 - c.y) * bianco, c.z + (1 - c.z) * bianco, 1
	gui.set_color(t.pieno, C)
end

return M
