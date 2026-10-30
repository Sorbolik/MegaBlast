-- La scheda di un'arma nuova, la Carta (Sergio, 29 ott; le proposte:
-- https://claude.ai/artifact/8ARwTr2xjcdXZxq7UhgnMK): al centro dello schermo
-- l'icona, il nome, una riga su cosa fa, tre barre a pallini (danno, gittata e
-- una che cambia col tipo) e come si usa coi comandi che hai. Si chiude con
-- PROVALA. Non sa niente della partita: la apre la battaglia quando trovi
-- un'arma nuova, e servirà anche alla scelta delle armi e all'Armeria.
--
--   local c = scheda.apri("missile", telefono)    -- telefono: come si usa col dito, se no col mouse
--   local c = scheda.apri("missile", telefono, true) -- rivista (scelta delle armi): niente ARMA NUOVA, si chiude con OK
--   if c:premi(x, y) then c:chiudi() end          -- un tocco: sul bottone? (x, y come gui.pick_node)
--   scheda.DATI.missile                           -- cosa fa e le barre, per chi la mostra altrove

local ui = require "ui.ui"
local hud = require "battaglia.hud"
local schermo = require "ui.schermo"

local M = {}

local C = ui.C
-- il tipo dell'arma: la scritta in alto, il colore del bordo (quello della
-- barra delle armi) e la terza barra
local TIPI = {
	primaria = { nome = "PRIMARIA", colore = C.BRACE, terza = "Area" },
	secondaria = { nome = "SECONDARIA", colore = C.ACCIAIO, terza = "Spinta" },
	movimento = { nome = "MOVIMENTO", colore = C.VIOLA },
	oggetto = { nome = "OGGETTO", colore = C.MENTA },
}

-- cosa fa, e i pallini (da 1 a 5) di danno, gittata e terza barra
M.DATI = {
	missile = { tipo = "primaria", cosa = "Spara una runa che esplode dove tocca: fa danno a chi è vicino e scava il terreno",
		barre = { 3, 4, 3 } },
	grenade = { tipo = "primaria", cosa = "Un uovo che rimbalza e scoppia dopo 3 secondi: cratere grande",
		barre = { 4, 3, 5 } },
	shards = { tipo = "primaria", cosa = "Una raffica di 8 schegge: rallenta chi colpisce", barre = { 3, 3, 2 } },
	punch = { tipo = "primaria", cosa = "Un montante da vicino: lancia in alto e incrina l'armatura", barre = { 4, 1, 1 } },
	sniper = { tipo = "primaria", cosa = "Parte veloce e cala a poco a poco; rimbalza e sbalza chi colpisce",
		barre = { 4, 5, 1 } },
	sword = { tipo = "secondaria", cosa = "Sempre con te: un colpo da vicino", barre = { 2, 1, 2 } },
	eagle = { tipo = "secondaria", cosa = "Un colpo dritto e subito; il rinculo ti spinge dall'altra parte",
		barre = { 3, 4, 4 } },
	mallet = { tipo = "secondaria", cosa = "Un colpo ad arco; in aria, se colpisce mentre cali, rimbalzi in alto",
		barre = { 3, 1, 4 } },
	lunge = { tipo = "secondaria", cosa = "Uno scatto che passa oltre chi hai davanti e lo colpisce", barre = { 3, 2, 3 } },
	bellows = { tipo = "secondaria", cosa = "Il soffio della forgia: spinge via chi hai davanti", barre = { 1, 2, 5 } },
	hook = { tipo = "movimento", cosa = "Aggancia un bordo e ti arrampichi; su un nemico, lo tiri da te" },
	parachute = { tipo = "oggetto", cosa = "Aprilo in aria: scendi piano e atterri senza farti male", in_aria = true },
	trap = { tipo = "oggetto", cosa = "Posala a terra: scatta quando ci passa un nemico" },
	shield = { tipo = "oggetto", cosa = "Ti ripara dai colpi fino al tuo prossimo turno" },
	trampoline = { tipo = "oggetto", cosa = "Posalo a terra: chi ci salta sopra vola in alto" },
}

local NOMI_BARRE = { "Danno", "Gittata" }
local SPENTO = vmath.vector4(1, 1, 1, 0.14)
local W, H = 560, 560
local LARGO = 480

-- come si usa, coi comandi che hai
local function uso(d, telefono)
	if d.tipo == "oggetto" then
		return d.in_aria and "In aria toccalo fra gli OGGETTI" or "Toccalo fra gli OGGETTI"
	end
	if telefono then
		return "Sposta l'analogico di destra per sistemare la traiettoria, rilascialo per far partire il colpo"
	end
	return "Trascina dal diavoletto per sistemare la traiettoria, lascia per far partire il colpo"
end

-- un testo che va a capo entro LARGO
local function riga(t, y, scala, colore, parent)
	local n = ui.testo(t, 0, y, scala, colore, parent)
	gui.set_line_break(n, true)
	gui.set_size(n, vmath.vector3(LARGO / (scala * 0.5), 200, 0))
	return n
end

function M.apri(arma, telefono, rivista)
	local d = assert(M.DATI[arma], "scheda sconosciuta: " .. tostring(arma))
	local tipo = TIPI[d.tipo]
	local col = tipo.colore
	local c = setmetatable({ arma = arma }, { __index = M })
	-- il velo scuro su tutto lo schermo, e la carta al centro
	c.radice = gui.new_box_node(vmath.vector3(640, 360, 0), vmath.vector3(0, 0, 0))
	local velo = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(1280 * schermo.PIENO, 720 * schermo.PIENO, 0))
	gui.set_color(velo, vmath.vector4(0, 0, 0, 0.62))
	gui.set_parent(velo, c.radice)
	local carta, bordo = ui.pannello(0, 0, W, H, c.radice)
	gui.set_color(bordo, col)
	ui.testo(rivista and tipo.nome or "ARMA NUOVA  ·  " .. tipo.nome, 0, 245, 0.8, col, carta)
	ui.alone(0, 150, 230, vmath.vector4(col.x, col.y, col.z, 0.4), carta)
	local icona = gui.new_box_node(vmath.vector3(0, 150, 0), vmath.vector3(130, 130, 0))
	gui.set_texture(icona, "armi")
	gui.play_flipbook(icona, arma .. "_icona")
	gui.set_parent(icona, carta)
	ui.titolo(hud.NOMI[arma] or string.upper(arma), 0, 58, 0.9, C.LUCE, carta)
	riga(d.cosa, 2, 0.9, C.TESTO, carta)
	local y = -62
	if d.barre then
		for i, v in ipairs(d.barre) do
			local nome = ui.testo(NOMI_BARRE[i] or tipo.terza, -190, y, 0.8, C.SPENTO, carta)
			gui.set_pivot(nome, gui.PIVOT_W)
			for k = 1, 5 do
				ui.disco(40 + (k - 1) * 34, y, 20, k <= v and col or SPENTO, carta)
			end
			y = y - 36
		end
	end
	riga(uso(d, telefono), d.barre and -188 or -110, 0.8, C.TESTO, carta)
	c.prova = ui.bottone({}, 0, -240, 250, 64, rivista and "OK" or "PROVALA", nil, { principale = true, colore = col }, carta)
	-- arriva con un piccolo salto
	gui.set_scale(carta, vmath.vector3(0.6, 0.6, 1))
	gui.animate(carta, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.35)
	return c
end

function M.premi(c, x, y)
	return gui.pick_node(c.prova, x, y)
end

function M.chiudi(c)
	gui.delete_node(c.radice)
end

return M
