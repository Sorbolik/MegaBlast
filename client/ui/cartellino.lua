-- Il cartellino di un giocatore (scheda personaggio, Sergio 31 ott): lo stesso
-- dappertutto, nello schieramento prima e durante la scelta delle armi, in
-- partita toccando la targa, nel profilo ("COSÌ TI VEDONO"), nelle partite
-- passate. Dall'alto: livello, nome e tre badge; il diavoletto (se c'è posto);
-- i quattro pezzi col loro livello e le tacche degli scatti; i poteri; le
-- quattro statistiche come scarto dalla base (barre dal centro: i pezzi danno
-- e tolgono, e con barre normali un +4% non si vedrebbe); globi, paracadute e
-- salti in aria; i punti dell'albero per ramo. I dati sono una vetrina
-- (menu/vetrina.lua). Forme e colori di ui/ui.lua, i pezzi dall'atlante del
-- diavoletto.
--
--   local c = cartellino.new(v, x, y, opz, parent)  -- x, y: centro in alto; opz: ritratto, tu
--   cartellino.update(c, dt)                         -- se ha il diavoletto, lo fa respirare
--   cartellino.distruggi(c)
--   cartellino.ALTO(opz) / cartellino.LARGO          -- quanto è grande
--   cartellino.badge(b, x, y, d, parent)             -- un badge da solo (scheda STATISTICHE)
--   cartellino.pezzo(p, squadra, x, y, d, parent)    -- un pezzo da solo (scheda SCHEDA)

local ui = require "ui.ui"
local game = require "sim.game"
local abilita = require "sim.abilita"
local equip = require "sim.equipaggiamento"
local pelli = require "battaglia.pelli"
local traguardi = require "menu.traguardi"
local vetrina = require "menu.vetrina"

local M = {}

local C = ui.C
M.LARGO = 286
local PAD = 14
local TESTA = 52          -- livello, nome e badge
local RITRATTO = 196      -- il diavoletto
local FIGURA_H = 124      -- quanto è alto il diavoletto fino alla testa (con la fiammella circa 170)
local PEZZO, PEZZO_GAP = 60, 6
local POTERI = 30
local ETICHETTA = 18
local RIGA = 21
local RISORSE = 24
local ALBERO = 12
local LEGENDA = 18

-- i pezzi nell'atlante del diavoletto (le pelli di Gabriella con la squadra)
local PEZZI_IMG = { mask = "testa", chest = "busto", cloak = "ala", legs = "gamba" }
local PELLE = pelli.pelli.gabriella_squadra.pezzi
-- i colori dei rami dell'albero, nell'ordine di abilita.BRANCHES
local RAMI = { C.ACCIAIO, C.MENTA, C.BRACE }
local SIGLE = { "MOB", "DIF", "ARS" }
local ROMANI = { "I", "II", "III", "IV" }

local function vec(x, y) return vmath.vector3(x, y, 0) end
local function con_alfa(c, a) return vmath.vector4(c.x, c.y, c.z, a) end

local function box(x, y, w, h, colore, parent)
	local n = gui.new_box_node(vec(x, y), vec(w, h))
	gui.set_color(n, colore)
	gui.set_parent(n, parent)
	return n
end

local function testo(t, x, y, scala, colore, parent, pivot)
	local n = ui.testo(t, x, y, scala, colore, parent)
	if pivot then gui.set_pivot(n, pivot) end
	return n
end

local function largo_testo(n)
	local m = resource.get_text_metrics(gui.get_font_resource(gui.get_font(n)), gui.get_text(n))
	return m.width * gui.get_scale(n).x
end

function M.ALTO(opz)
	opz = opz or {}
	return PAD + TESTA + (opz.ritratto and RITRATTO or 0) + PEZZO + 10 + POTERI + ETICHETTA + 4 * RIGA
		+ RISORSE + ETICHETTA + ALBERO + LEGENDA + 6
end

-- Un badge: la forma della statistica nel colore del grado, col grado scritto dentro
function M.badge(b, x, y, d, parent)
	local s = traguardi.BY_ID[b.id]
	local col = C.GRADI[b.grado] or C.SPENTO
	local radice = box(x, y, 0, 0, col, parent)
	gui.set_visible(radice, false)
	local function forma(k, colore)
		local n
		if s.forma == "cerchio" then
			n = ui.disco(0, 0, d * k, colore, radice)
		elseif s.forma == "esagono" then
			n = ui.disco(0, 0, d * k, colore, radice)
			gui.set_perimeter_vertices(n, 6)
		elseif s.forma == "stella" then
			n = ui.stella(0, 0, d * 1.15 * k, colore, radice)
		else
			n = box(0, 0, d * 0.72 * k, d * 0.72 * k, colore, radice)
			gui.set_euler(n, vmath.vector3(0, 0, 45))
		end
		return n
	end
	forma(1, col)
	forma(0.74, con_alfa(C.FONDO, 0.9))
	testo(ROMANI[b.grado] or "", 0, 0, d / 52, col, radice)
	return radice
end

-- Un pezzo: il riquadro col bordo del tier, l'immagine, il livello e le tacche
-- degli scatti. p = { slot, set, livello, tier }
function M.pezzo(p, squadra, x, y, d, parent)
	local col = C.SQUADRA[squadra] or C.LUCE
	local vuoto = not p.set
	local bordo_col = vuoto and C.LINEA or p.tier >= 3 and C.ORO or p.tier == 2 and C.ACCIAIO
		or con_alfa(C.LUCE, 0.5)
	local fuori, bordo = ui.pannello(x, y, d, d, parent)
	gui.set_color(bordo, bordo_col)
	if p.tier and p.tier >= equip.TIERS and not vuoto then
		local a = ui.alone(0, 0, d * 1.6, con_alfa(C.ORO, 0.35), fuori)
		gui.move_below(a, bordo)
	end
	-- l'immagine del pezzo, intera nel riquadro
	local img = PELLE[PEZZI_IMG[p.slot]]
	if img then
		local k = (d - 10) / math.max(img.w, img.h)
		local alfa = vuoto and 0.22 or 1
		local n = box(0, 0, img.w * k, img.h * k, con_alfa(vmath.vector4(1, 1, 1, 1), alfa), fuori)
		gui.set_texture(n, "diavoletto")
		gui.play_flipbook(n, img.img)
		if img.tinta then
			local t = box(0, 0, img.w * k, img.h * k, con_alfa(col, alfa), fuori)
			gui.set_texture(t, "diavoletto")
			gui.play_flipbook(t, img.tinta)
		end
	end
	if vuoto then return fuori end
	-- le tacche degli scatti in alto a sinistra: oro quelli presi
	for i, s in ipairs(equip.SCATTI) do
		local t = box(-d / 2 + 8 + (i - 1) * 10, d / 2 - 8, 7, 7, p.livello >= s and C.ORO or con_alfa(C.LUCE, 0.3), fuori)
		gui.set_euler(t, vmath.vector3(0, 0, 45))
	end
	-- il livello in basso a destra
	local lw = p.livello >= 10 and 28 or 22
	box(d / 2 - lw / 2 + 4, -d / 2 + 4, lw + 3, 21, C.LUCE, fuori)
	box(d / 2 - lw / 2 + 4, -d / 2 + 4, lw, 18, C.FONDO, fuori)
	testo(tostring(p.livello), d / 2 - lw / 2 + 4, -d / 2 + 4, 0.62, C.LUCE, fuori)
	return fuori
end

-- Una pillola dorata per potere; sx: il bordo sinistro
-- quanto è largo un testo di ui.testo a quella scala, senza crearlo
local function largo(t, scala)
	return resource.get_text_metrics(gui.get_font_resource(hash("titolo")), t).width * scala * 0.5
end

-- le pillole dei poteri: prima le forme, poi il testo (così ci sta sopra)
local function pillole(poteri, sx, y, spazio, parent)
	if #poteri == 0 then
		local w = largo("nessun potere", 0.58) + 16
		box(sx + w / 2, y, w + 2, 24, C.LINEA, parent)
		box(sx + w / 2, y, w, 22, C.PANNELLO, parent)
		testo("nessun potere", sx + 8, y, 0.58, C.SPENTO, parent, gui.PIVOT_W)
		return
	end
	local x = sx
	for _, p in ipairs(poteri) do
		local w = largo(p, 0.58) + 16
		if x + w > sx + spazio then break end
		box(x + w / 2, y, w + 3, 25, C.ORO, parent)
		box(x + w / 2, y, w, 22, C.FONDO, parent)
		testo(p, x + 8, y, 0.58, C.ORO, parent, gui.PIVOT_W)
		x = x + w + 6
	end
end

function M.new(v, x, y, opz, parent)
	opz = opz or {}
	local c = { v = v }
	local W, H = M.LARGO, M.ALTO(opz)
	local col = C.SQUADRA[v.squadra] or C.LUCE
	c.alto = H
	-- il bordo nel colore della squadra: pieno per chi gioca qui
	c.root, c.bordo = ui.pannello(x, y - H / 2, W, H, parent)
	gui.set_color(c.bordo, opz.tu and col or con_alfa(col, 0.6))
	local sx, dx = -W / 2 + PAD, W / 2 - PAD
	local top = H / 2 - PAD

	-- livello, nome, badge
	local cy = top - TESTA / 2 + 4
	ui.anello(sx + 22, cy, 44, 3, col, c.root)
	if v.livello then
		testo(tostring(v.livello), sx + 22, cy - (v.torneo and 4 or 0), 0.95, col, c.root)
		if v.torneo then testo("TORNEO", sx + 22, cy + 11, 0.3, col, c.root) end
	else
		testo(v.bot and "BOT" or "–", sx + 22, cy, v.bot and 0.62 or 0.95, col, c.root)
	end
	local nome = ui.titolo(v.nome or "?", sx + 52, cy + 8, 0.5, C.LUCE, c.root)
	gui.set_pivot(nome, gui.PIVOT_W)
	testo(string.upper(v.sotto or ""), sx + 52, cy - 13, 0.52, C.SPENTO, c.root, gui.PIVOT_W)
	for i, b in ipairs(v.badge or {}) do
		M.badge(b, dx - 12 - (#v.badge - i) * 28, cy + 2, 25, c.root)
	end
	local yy = top - TESTA

	-- il diavoletto
	if opz.ritratto then
		local scoria = require "battaglia.scoria"
		-- la cornice scura del ritratto, col diavoletto dentro
		box(0, yy - RITRATTO / 2 + 2, 128, RITRATTO - 12, con_alfa(C.FONDO, 0.7), c.root)
		local posa = box(0, yy - RITRATTO + 16, 0, 0, C.LUCE, c.root)
		gui.set_visible(posa, false)
		c.figura = scoria.new(col, scoria.PERSONAGGIO)
		-- la fiammella "in attesa" (la fiamma grande dice di chi è il turno, e qui non lo è
		-- di nessuno): resta dentro il ritratto
		c.st = { x = 0, y = 0, facing = v.verso or 1, grounded = true, moving = 0, turno = false }
		scoria.update(c.figura, 0, c.st)
		local k = FIGURA_H / game.DISEGNO_H
		gui.set_scale(posa, vmath.vector3(k, k, 1))
		ui.alone(0, 70 / k, 200 / k, con_alfa(col, 0.18), posa)
		gui.set_parent(c.figura.root, posa)
		scoria.set_enabled(c.figura, true)
		yy = yy - RITRATTO
	end

	-- i pezzi
	for i, p in ipairs(v.pezzi or {}) do
		M.pezzo(p, v.squadra, sx + PEZZO / 2 + (i - 1) * (PEZZO + PEZZO_GAP) + 1, yy - PEZZO / 2, PEZZO, c.root)
	end
	yy = yy - PEZZO - 10

	-- i poteri
	pillole(v.poteri or {}, sx, yy - POTERI / 2 + 2, W - 2 * PAD, c.root)
	yy = yy - POTERI

	-- le statistiche: barre dal centro (la base è uguale per tutti)
	testo("STATISTICHE", sx, yy - ETICHETTA / 2, 0.42, C.SPENTO, c.root, gui.PIVOT_W)
	yy = yy - ETICHETTA
	local bx, bw = sx + 62, W - 2 * PAD - 62 - 50
	for _, r in ipairs(vetrina.righe(v)) do
		local ry = yy - RIGA / 2
		testo(r.nome, sx, ry, 0.62, C.TESTO, c.root, gui.PIVOT_W)
		box(bx + bw / 2, ry, bw, 10, con_alfa(C.LUCE, 0.08), c.root)
		if r.scarto ~= 0 then
			local w = math.abs(r.scarto) * bw / 2
			local f = box(bx + bw / 2, ry, w, 10, r.scarto > 0 and C.MENTA or C.BRACE, c.root)
			gui.set_pivot(f, r.scarto > 0 and gui.PIVOT_W or gui.PIVOT_E)
		end
		box(bx + bw / 2, ry, 2, 16, con_alfa(C.LUCE, 0.7), c.root)
		testo(r.valore, dx, ry, 0.62, r.scarto > 0 and C.MENTA or r.scarto < 0 and C.BRACE or C.TESTO, c.root, gui.PIVOT_E)
		yy = yy - RIGA
	end

	-- globi, paracadute, salti in aria
	local rs = vetrina.risorse(v)
	local ry = yy - RISORSE / 2 - 2
	local voci = {
		{ rs.globi, rs.globi == 1 and "globo" or "globi", C.VIOLA },
		{ rs.paracadute, "paracad.", C.MENTA },
		{ rs.aria, "in aria", C.ACCIAIO, true },
	}
	local x = sx
	for _, vo in ipairs(voci) do
		if vo[4] then ui.anello(x + 6, ry, 12, 2, vo[3], c.root) else ui.disco(x + 6, ry, 12, vo[3], c.root) end
		local n = testo(vo[1] .. " " .. vo[2], x + 16, ry, 0.6, C.TESTO, c.root, gui.PIVOT_W)
		x = x + 16 + largo_testo(n) + 12
	end
	yy = yy - RISORSE

	-- l'albero: venti tacche colorate per ramo
	testo("ALBERO · " .. (v.punti or abilita.POINTS_MAX) .. " PUNTI", sx, yy - ETICHETTA / 2, 0.42, C.SPENTO, c.root, gui.PIVOT_W)
	yy = yy - ETICHETTA
	local n, tw = abilita.POINTS_MAX, (W - 2 * PAD - (abilita.POINTS_MAX - 1) * 2) / abilita.POINTS_MAX
	local colori = {}
	for i, punti in ipairs(v.albero or {}) do
		for _ = 1, punti do colori[#colori + 1] = RAMI[i] end
	end
	for i = 1, n do
		box(sx + tw / 2 + (i - 1) * (tw + 2), yy - ALBERO / 2, tw, 9, colori[i] or con_alfa(C.LUCE, 0.1), c.root)
	end
	yy = yy - ALBERO
	local ly = yy - LEGENDA / 2 - 2
	for i = 1, #RAMI do
		local lx = sx + (i - 1) * (W - 2 * PAD) / #RAMI
		box(lx + 4, ly, 8, 8, RAMI[i], c.root)
		testo(SIGLE[i] .. " " .. ((v.albero or {})[i] or 0), lx + 13, ly, 0.55, C.SPENTO, c.root, gui.PIVOT_W)
	end
	return c
end

function M.update(c, dt)
	if c.figura then
		require("battaglia.scoria").update(c.figura, dt, c.st)
	end
end

function M.distruggi(c)
	if c.root then gui.delete_node(c.root) end
	c.root = nil
end

return M
