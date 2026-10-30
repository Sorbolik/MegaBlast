-- Controller (gamepad) via Bluetooth o USB: Xbox, PlayStation e generici, sul
-- telefono Android, sul computer e nel browser. Qui c'è solo la lettura dei
-- tasti, senza nodi GUI, così si prova con luajit (tests/battaglia_test.lua);
-- cosa fa ogni tasto lo decide game.gui_script (docs/controller.md).
--
-- I controller che Defold conosce (/builtins/input/default.gamepads) arrivano
-- come azioni pad_* di input/game.input_binding. Quelli che non conosce danno
-- solo l'azione grezza pad_grezzo: su Android e nel browser i tasti hanno lo
-- stesso ordine per tutti (Android li numera dai codici standard, il browser
-- segue lo "standard gamepad"), quindi li leggiamo da lì.
--
--   local controller = require "ui.controller"
--   local c = controller.new(sistema)            -- sistema: sys.get_sys_info().system_name
--   local ev = controller.input(c, action_id, action)
--   -- nil: non è un'azione del controller. Altrimenti la lista dei tasti che
--   -- cambiano: { nome = "a", premuto = true } (premuto false: lasciato); nome
--   -- "a" "b" "x" "y" "lb" "rb" "lt" "rt" "start" "select", la croce "su" "giu"
--   -- "sinistra" "destra" e la levetta sinistra spinta oltre metà, come la croce
--   -- ma con levetta = true. ui = la stessa cosa per i menu (ui.tocco).
--   c.sx, c.dx                                    -- le levette: { x, y }, y in su, lunghezza al massimo 1
--   c.giu[nome]                                   -- il tasto è tenuto?
--   controller.comando(c, tasto) / tasto_di(c, comando) -- la mappatura della battaglia (c.tasti)
--   controller.assegna(c, comando, tasto)         -- dalle impostazioni: i due comandi si scambiano i tasti
--   controller.usa(c, salvati) / da_salvare(c) / base(c) -- la mappatura del profilo, da salvare, quella di Sergio
--   controller.nome(c, tasto)                     -- come si chiama su questo controller ("A", "CROCE", "ZR"...)
--   controller.nome_di(comando)                   -- il nome del tasto di un comando, sul controller in uso
--   c.famiglia                                    -- "xbox", "playstation" o "nintendo" (dal nome del controller)
--   c.connesso                                    -- c'è (o c'è stato) un controller
--   c.su                                          -- -1 dove gli assi verticali arrivano capovolti (Android)

local M = {}

-- metà di una levetta: { levetta, asse, segno }
local ASSI = {
	pad_sx_sinistra = { "sx", "x", -1 }, pad_sx_destra = { "sx", "x", 1 },
	pad_sx_su = { "sx", "y", 1 }, pad_sx_giu = { "sx", "y", -1 },
	pad_dx_sinistra = { "dx", "x", -1 }, pad_dx_destra = { "dx", "x", 1 },
	pad_dx_su = { "dx", "y", 1 }, pad_dx_giu = { "dx", "y", -1 },
}
local TASTI = { pad_a = "a", pad_b = "b", pad_x = "x", pad_y = "y", pad_lb = "lb", pad_rb = "rb",
	pad_lt = "lt", pad_rt = "rt", pad_start = "start", pad_select = "select",
	pad_su = "su", pad_giu = "giu", pad_sinistra = "sinistra", pad_destra = "destra" }
-- per i menu (ui.tocco): la croce e la levetta muovono la luce, A conferma,
-- B torna indietro, Y apre la scheda (al posto del tocco lungo), Start il menù
M.UI = { su = "su", giu = "giu", sinistra = "sinistra", destra = "destra", a = "conferma", b = "indietro",
	y = "scheda", start = "menu" }
-- In battaglia: tasto -> comando, la mappatura di base (Sergio, 30 ott). I
-- tasti hanno il nome del loro posto sul controller, come su Xbox: a è quello
-- in basso, b a destra, x a sinistra, y in alto. Le levette sono fisse e
-- fanno come sul telefono: la sinistra cammina e, spinta in su, salta; la
-- destra mira (direzione e potenza). Start apre sempre la rotellina; tutto il
-- resto si cambia dalle IMPOSTAZIONI (menu/impostazioni.lua), che salvano
-- c.tasti nel profilo.
M.BATTAGLIA = {
	lb = "primaria",        -- la primaria dopo, a giro
	rb = "secondaria",      -- la secondaria dopo, a giro
	rt = "spara",           -- con la mira della levetta destra
	a = "teletrasporto",
	x = "rampino",
	y = "paracadute",
	lt = "oggetti",         -- l'oggetto dopo nella colonna OGGETTI, a giro
	giu = "usa_oggetto",    -- usa quello acceso (croce giù)
	b = "baratto",          -- salta il secondo attacco (+1 teletrasporto)
	start = "rotellina",
	select = "zoom",
}
-- i comandi che si cambiano, nell'ordine delle impostazioni, e i tasti che si possono dare
M.COMANDI = { "spara", "primaria", "secondaria", "teletrasporto", "rampino", "paracadute", "oggetti", "usa_oggetto",
	"baratto", "zoom" }
M.LIBERI = { a = true, b = true, x = true, y = true, lb = true, rb = true, lt = true, rt = true, select = true,
	su = true, giu = true, sinistra = true, destra = true }

-- La famiglia del controller, dal nome che dà il sistema: i tasti si
-- chiamano (e si disegnano) come sopra i tasti veri. Nintendo ha A a destra e
-- B in basso: lo stesso posto, un altro nome.
M.FAMIGLIE = {
	xbox = { a = "A", b = "B", x = "X", y = "Y", lb = "LB", rb = "RB", lt = "LT", rt = "RT", start = "MENU", select = "VISTA" },
	playstation = { a = "X", b = "CERCHIO", x = "QUADRATO", y = "TRIANGOLO", lb = "L1", rb = "R1", lt = "L2", rt = "R2",
		start = "OPTIONS", select = "CREATE" },
	nintendo = { a = "B", b = "A", x = "Y", y = "X", lb = "L", rb = "R", lt = "ZL", rt = "ZR", start = "+", select = "-" },
}
M.CROCE = { su = "CROCE SU", giu = "CROCE GIÙ", sinistra = "CROCE SX", destra = "CROCE DX" }
-- (in quest'ordine: "Xbox Wireless Controller" è Xbox, il solo "Wireless
-- Controller" è il nome che dà Android al DualSense e al DualShock)
local RICONOSCI = {
	{ "xbox", { "xbox", "x%-box", "xinput", "microsoft", "045e" } },
	{ "nintendo", { "nintendo", "switch", "joy%-con", "pro controller", "057e" } },
	{ "playstation", { "playstation", "dualsense", "dualshock", "sony", "wireless controller", "054c" } },
}
function M.famiglia(nome)
	nome = string.lower(nome or "")
	for _, f in ipairs(RICONOSCI) do
		for _, parola in ipairs(f[2]) do
			if nome:find(parola) then return f[1] end
		end
	end
	-- gli altri: coi nomi di Xbox, i più comuni
	return "xbox"
end
-- la levetta sinistra conta come la croce oltre questa spinta (e torna sotto RITORNO)
local SPINTA, RITORNO = 0.6, 0.4
-- grilletti analogici: premuti oltre metà corsa
local GRILLETTO = 0.5
-- zona morta dei controller sconosciuti (per quelli noti la mette Defold)
local MORTA = 0.2

-- Controller sconosciuti: i numeri dei tasti e degli assi (da 0) nell'azione
-- grezza. Android: gli stessi del controller Xbox e PlayStation in
-- default.gamepads (assi 0-1 levetta sinistra, 2-3 destra, 4-5 grilletti,
-- 6-7 la croce; la croce anche come tasti 11-14). Browser: lo standard gamepad.
local GREZZI = {
	Android = { tasti = { a = 0, b = 1, x = 3, y = 6, lb = 4, rb = 5, start = 15, select = 16,
		su = 11, giu = 12, sinistra = 13, destra = 14 },
		assi = { sx = { 0, 1 }, dx = { 2, 3 }, lt = 4, rt = 5, croce = { 6, 7 } } },
	HTML5 = { tasti = { a = 0, b = 1, x = 2, y = 3, lb = 4, rb = 5, lt = 6, rt = 7, select = 8, start = 9,
		su = 12, giu = 13, sinistra = 14, destra = 15 },
		assi = { sx = { 0, 1 }, dx = { 2, 3 } } },
}

local GREZZO, CONNESSO = hash("pad_grezzo"), hash("pad_connesso")
local AZIONI = {}
for nome, v in pairs(ASSI) do AZIONI[hash(nome)] = v end
local NOMI = {}
for nome, v in pairs(TASTI) do NOMI[hash(nome)] = v end

-- Su Android le levette arrivano con l'asse verticale capovolto (provato da
-- Sergio col telefono, 30 ott): giù è su, per i controller noti e i grezzi
local CAPOVOLTO = { Android = true }

function M.new(sistema)
	local c = { sx = { x = 0, y = 0 }, dx = { x = 0, y = 0 }, giu = {}, mezzi = {}, ignoti = {},
		crude = { sx = { x = 0, y = 0 }, dx = { x = 0, y = 0 } },
		grezzi = GREZZI[sistema], ev = {}, su = CAPOVOLTO[sistema] and -1 or 1, famiglia = "xbox", tasti = {} }
	for t, cmd in pairs(M.BATTAGLIA) do c.tasti[t] = cmd end
	return c
end

function M.comando(c, tasto)
	return c.tasti[tasto]
end

-- Il tasto di un comando (nil se non ne ha), in un ordine fisso
local ORDINE = { "a", "b", "x", "y", "lb", "rb", "lt", "rt", "start", "select", "su", "giu", "sinistra", "destra" }
function M.tasto_di(c, comando)
	for _, t in ipairs(ORDINE) do
		if c.tasti[t] == comando then return t end
	end
end

-- Dà il tasto al comando; il comando che lo aveva prende il tasto lasciato libero
function M.assegna(c, comando, tasto)
	if not M.LIBERI[tasto] then return false end
	local prima, altro = M.tasto_di(c, comando), c.tasti[tasto]
	c.tasti[tasto] = comando
	if prima and prima ~= tasto then c.tasti[prima] = altro end
	return true
end

-- La mappatura salvata nel profilo (tasto -> comando): si prende solo se ha
-- tutti i comandi, ognuno su un tasto libero; Start resta alla rotellina
function M.usa(c, tasti)
	if type(tasti) ~= "table" then return false end
	local visti = {}
	for t, cmd in pairs(tasti) do
		if not M.LIBERI[t] or visti[cmd] then return false end
		visti[cmd] = true
	end
	for _, cmd in ipairs(M.COMANDI) do
		if not visti[cmd] then return false end
	end
	c.tasti = { start = "rotellina" }
	for t, cmd in pairs(tasti) do c.tasti[t] = cmd end
	return true
end

-- Da salvare nel profilo: senza Start
function M.da_salvare(c)
	local t = {}
	for tasto, cmd in pairs(c.tasti) do
		if tasto ~= "start" then t[tasto] = cmd end
	end
	return t
end

function M.base(c)
	c.tasti = {}
	for t, cmd in pairs(M.BATTAGLIA) do c.tasti[t] = cmd end
end

function M.nome(c, tasto)
	return M.CROCE[tasto] or M.FAMIGLIE[c.famiglia][tasto] or string.upper(tasto or "")
end

-- Il controller in uso, per le scritte delle schede e della scelta delle armi
-- (game.gui_script lo mette qui): il nome del tasto di un comando
M.attuale = nil
function M.nome_di(comando)
	local c = M.attuale
	if not c then return "" end
	return M.nome(c, M.UI_FISSI[comando] or M.tasto_di(c, comando))
end
-- i tasti fissi dei menu
M.UI_FISSI = { scheda = "y", conferma = "a", indietro = "b" }

local function evento(c, nome, premuto, levetta)
	if (c.giu[nome] or false) == premuto then return end
	c.connesso = true
	c.giu[nome] = premuto or nil
	c.ev[#c.ev + 1] = { nome = nome, premuto = premuto, levetta = levetta, ui = M.UI[nome] }
end

-- La levetta sinistra spinta oltre SPINTA fa da croce (per i menu e gli oggetti)
local DIREZIONI = { { "sinistra", "x", -1 }, { "destra", "x", 1 }, { "su", "y", 1 }, { "giu", "y", -1 } }
local function levetta_croce(c)
	for _, d in ipairs(DIREZIONI) do
		local v = c.sx[d[2]] * d[3]
		local nome = "levetta_" .. d[1]
		if v > SPINTA and not c.giu[nome] then
			c.giu[nome] = true
			c.ev[#c.ev + 1] = { nome = d[1], premuto = true, levetta = true, ui = d[1] }
		elseif v < RITORNO and c.giu[nome] then
			c.giu[nome] = nil
		end
	end
end

-- una levetta da due assi grezzi (y in giù, su: -1 se arriva capovolto), con la zona morta
local function levetta_grezza(l, assi, i, su)
	local x, y = assi[i[1] + 1] or 0, -(assi[i[2] + 1] or 0) * su
	if x * x + y * y < MORTA * MORTA then x, y = 0, 0 end
	l.x, l.y = x, y
end

local function grezzo(c, action)
	local g = c.grezzi
	local tasti, assi = action.gamepad_buttons or {}, action.gamepad_axis or {}
	levetta_grezza(c.sx, assi, g.assi.sx, c.su)
	levetta_grezza(c.dx, assi, g.assi.dx, c.su)
	local croce = g.assi.croce
	local cx, cy = croce and (assi[croce[1] + 1] or 0) or 0, croce and (assi[croce[2] + 1] or 0) or 0
	-- la croce come cappello (hat): 1 su, 2 destra, 4 giù, 8 sinistra
	local hat = (action.gamepad_hats or {})[1] or 0
	local bit = function(b) return math.floor(hat / b) % 2 == 1 end
	for nome, i in pairs(g.tasti) do
		local giu = (tasti[i + 1] or 0) > 0.5
		if nome == "su" then giu = giu or cy < -0.5 or bit(1)
		elseif nome == "giu" then giu = giu or cy > 0.5 or bit(4)
		elseif nome == "sinistra" then giu = giu or cx < -0.5 or bit(8)
		elseif nome == "destra" then giu = giu or cx > 0.5 or bit(2) end
		evento(c, nome, giu)
	end
	for _, nome in ipairs({ "lt", "rt" }) do
		if g.assi[nome] then evento(c, nome, (assi[g.assi[nome] + 1] or 0) > GRILLETTO) end
	end
end

-- L'ordine degli eventi conta (la simulazione li prova uno a uno): per i tasti
-- grezzi si ordinano per nome
local function ordina(a, b) return a.nome < b.nome end

function M.input(c, action_id, action)
	if not action_id then return nil end
	local ev = c.ev
	for i = #ev, 1, -1 do ev[i] = nil end
	local asse = AZIONI[action_id]
	local nome = NOMI[action_id]
	if asse then
		c.mezzi[action_id] = (not action.released and action.value) or 0
		local l, r = c[asse[1]], c.crude[asse[1]]
		local piu, meno
		for id, a in pairs(AZIONI) do
			if a[1] == asse[1] and a[2] == asse[2] then
				if a[3] > 0 then piu = c.mezzi[id] or 0 else meno = c.mezzi[id] or 0 end
			end
		end
		r[asse[2]] = ((piu or 0) - (meno or 0)) * (asse[2] == "y" and c.su or 1)
		local m = math.max(1, math.sqrt(r.x * r.x + r.y * r.y))
		l.x, l.y = r.x / m, r.y / m
		if asse[1] == "sx" then levetta_croce(c) end
	elseif nome then
		local v = (not action.released) and (action.value or 1) or 0
		evento(c, nome, v > ((nome == "lt" or nome == "rt") and GRILLETTO or 0.5))
	elseif action_id == CONNESSO then
		-- un controller che Defold non conosce: lo leggiamo dall'azione grezza
		c.ignoti[action.gamepad or 0] = action.gamepad_unknown or nil
		c.famiglia = M.famiglia(action.gamepad_name)
		c.connesso = true
		return ev
	elseif action_id == GREZZO then
		if not (c.grezzi and c.ignoti[action.gamepad or 0]) then return ev end
		grezzo(c, action)
		levetta_croce(c)
		table.sort(ev, ordina)
	else
		return nil
	end
	return ev
end

-- La levetta è spinta? (per sapere se si sta usando il controller)
function M.spinta(l, soglia)
	return l.x * l.x + l.y * l.y > (soglia or 0.3) ^ 2
end

return M
