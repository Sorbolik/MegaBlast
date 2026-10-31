-- Il PROFILO (scheda personaggio, Sergio 31 ott): si apre toccando il proprio
-- diavoletto nella home. Tre schede, una cosa per scheda:
--   SCHEDA       il diavoletto grande coi pezzi indicati, il cartellino come lo
--                vedono gli altri ("COSÌ TI VEDONO"), il prossimo scatto di ogni
--                pezzo e l'ARMERIA; in alto i tre assetti (gli altri vedono l'attivo)
--   STATISTICHE  quattro numeri in alto e ogni statistica col suo badge nella
--                stessa riga (toccandola il badge va accanto al nome); a destra
--                il danno per arma. Filtro per modo, dal 2 contro 2
--   PARTITE      le ultime 10: com'è andata giro per giro, i momenti (toccandone
--                uno il replay parte da lì), chi c'era (toccando un giocatore il
--                suo cartellino com'era quella volta) e RIVEDI
-- Lo storico sta qui e non in un bottone della home: le partite sono roba tua,
-- e dal podio RIVEDI porta dritto al replay (decisione di Sergio, 31 ott).
-- La schermata si ricostruisce a ogni tocco, come l'armeria.
--
--   local s = profilo_schede.new(prof, scheda, colore, replay_ok, numero)  -- scheda: "scheda" (di base), "statistiche", "partite"
--                                                      -- replay_ok(numero): c'è il replay di quella partita?
--                                                      -- numero: la partita da mostrare in PARTITE
--   profilo_schede.update(s, dt)
--   profilo_schede.on_input(s, action_id, action) -> "indietro", "armeria", { rivedi = numero, da = tick } o nil
--   profilo_schede.distruggi(s)

local ui = require "ui.ui"
local game = require "sim.game"
local equip = require "sim.equipaggiamento"
local maps = require "sim.maps"
local profilo = require "menu.profilo"
local traguardi = require "menu.traguardi"
local vetrina = require "menu.vetrina"
local cartellino = require "ui.cartellino"
local scoria = require "battaglia.scoria"

local M = {}

local C = ui.C
local W, H = 1280, 720
local TOUCH = hash("touch")
local ARMI = { missile = "Lanciarune", grenade = "Uovo", shards = "Schegge", punch = "Pugno", sniper = "Cecchino",
	sword = "Lama", eagle = "Tonante", mallet = "Maglio", lunge = "Affondo", bellows = "Mantice" }
local DEL = { fornace = "della" }
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

local function titolo(t, x, y, scala, colore, parent, pivot)
	local n = ui.titolo(t, x, y, scala, colore, parent)
	if pivot then gui.set_pivot(n, pivot) end
	return n
end

-- un pezzo di schermo che si tocca senza disegnare niente (righe, momenti, giocatori)
local function zona(s, x, y, w, h, azione, parent)
	local n = box(x, y, w, h, C.LUCE, parent)
	gui.set_visible(n, false)
	s.bottoni[#s.bottoni + 1] = { nodo = n, bordo = n, azione = azione, colore = con_alfa(C.LUCE, 0), riposo = con_alfa(C.LUCE, 0) }
	return n
end

local function migliaia(n)
	local s = tostring(math.floor(n + 0.5))
	local out = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
	return (out:gsub("^%.", ""))
end

local function nome_pezzo(set, slot)
	local nome = slot.name:sub(1, 1) .. slot.name:sub(2):lower()
	local s = equip.BY_ID[set]
	local n = s.name:sub(1, 1) .. s.name:sub(2):lower()
	return nome .. " " .. (DEL[set] or "del") .. " " .. n
end

-- Scheda SCHEDA --------------------------------------------------------------------

local function scheda_scheda(s, parent)
	local p = s.prof
	local v = vetrina.da_profilo(p, "Tu", 1, "ASSETTO " .. p.attivo)
	v.tu = true
	local col = s.colore
	testo("ASSETTO", 44, 612, 0.7, C.SPENTO, parent, gui.PIVOT_W)
	for i = 1, #p.assetti do
		ui.scheda(s.bottoni, 64 + (i - 1) * 50, 574, 42, 42, tostring(i), "assetto:" .. i, p.attivo == i, parent)
	end
	-- il diavoletto grande
	local posa = box(245, 62, 0, 0, C.LUCE, parent)
	gui.set_visible(posa, false)
	s.figura = scoria.new(col, scoria.PERSONAGGIO)
	-- la fiammella "in attesa", come nei cartellini: quella grande è del turno
	s.st = { x = 0, y = 0, facing = 1, grounded = true, moving = 0, turno = false }
	scoria.update(s.figura, 0, s.st)
	-- alto 330 fino alla testa, circa 460 con la fiammella
	local k = 330 / game.DISEGNO_H
	gui.set_scale(posa, vmath.vector3(k, k, 1))
	ui.alone(0, 200 / k, 560 / k, con_alfa(col, 0.2), posa)
	local suolo = ui.alone(0, 0, 300 / k, C.OMBRA, posa)
	gui.set_blend_mode(suolo, gui.BLEND_ALPHA)
	gui.set_scale(suolo, vmath.vector3(1, 0.16, 1))
	gui.set_parent(s.figura.root, posa)
	scoria.set_enabled(s.figura, true)
	-- i pezzi indicati: maschera e corazza a destra, mantello a sinistra, gambali in basso
	local richiami = { mask = { 290, 1 }, chest = { 170, 1 }, cloak = { 215, -1 }, legs = { 100, 1 } }
	for i, slot in ipairs(equip.SLOTS) do
		local r = richiami[slot.id]
		local pz = v.pezzi[i]
		local scritta = slot.name .. (pz.set and (" " .. pz.livello) or " · VUOTO")
		local lx = r[2] > 0 and 420 or 40
		testo(scritta, lx, r[1] + 12, 0.75, pz.set and C.LUCE or C.SPENTO, parent, gui.PIVOT_W)
		box(r[2] > 0 and 345 or 100, r[1], r[2] > 0 and 150 or 120, 2, C.LINEA, parent)
	end
	-- come ti vedono gli altri
	testo("COSÌ TI VEDONO", 590, 612, 0.7, C.ORO, parent, gui.PIVOT_W)
	cartellino.new(v, 590 + cartellino.LARGO / 2, 594, { tu = true }, parent)
	-- i prossimi scatti di ogni pezzo
	local pan = ui.pannello(1072, 318, 336, 588, parent)
	titolo("PROSSIMI SCATTI", -146, 264, 0.55, C.LUCE, pan, gui.PIVOT_W)
	testo("ogni 10 livelli un aspetto nuovo, al 30 la variante B", -146, 236, 0.55, C.SPENTO, pan, gui.PIVOT_W)
	for i, slot in ipairs(equip.SLOTS) do
		local pz = v.pezzi[i]
		local y = 180 - (i - 1) * 100
		cartellino.pezzo(pz, 1, -132, y, 56, pan)
		testo(slot.name, -94, y + 24, 0.5, C.SPENTO, pan, gui.PIVOT_W)
		if pz.set then
			testo(nome_pezzo(pz.set, slot), -94, y + 4, 0.72, C.LUCE, pan, gui.PIVOT_W)
			local prossimo = equip.prossimo_scatto(pz.livello)
			local b = ui.barra(-94 + 116, y - 16, 232, 8, C.ORO, pan)
			if prossimo then
				local prima = 0
				for _, sc in ipairs(equip.SCATTI) do if sc < prossimo then prima = sc end end
				ui.barra_valore(b, (pz.livello - prima) / (prossimo - prima))
				local tier = equip.tier(prossimo)
				local cosa = "al " .. prossimo .. ": aspetto " .. ROMANI[tier]
				if tier >= equip.TIERS then cosa = cosa .. " e variante B" end
				testo(cosa, -94, y - 34, 0.55, C.ORO, pan, gui.PIVOT_W)
			else
				ui.barra_valore(b, 1)
				testo("tutti gli scatti presi", -94, y - 34, 0.55, C.ORO, pan, gui.PIVOT_W)
			end
		else
			testo("nessun pezzo", -94, y + 4, 0.72, C.SPENTO, pan, gui.PIVOT_W)
			testo("sceglilo nell'ARMERIA", -94, y - 18, 0.55, C.SPENTO, pan, gui.PIVOT_W)
		end
	end
	ui.bottone(s.bottoni, 0, -248, 296, 56, "ARMERIA", "armeria", nil, pan)
end

-- Scheda STATISTICHE ---------------------------------------------------------------

local function scheda_statistiche(s, parent)
	local p = s.prof
	local x = 44
	for _, g in ipairs(profilo.GRUPPI) do
		local nome = profilo.NOMI_GRUPPI[g]
		local w = 24 + #nome * 11
		ui.scheda(s.bottoni, x + w / 2, 610, w, 40, nome, "gruppo:" .. g, s.gruppo == g, parent)
		x = x + w + 8
	end
	local st = profilo.statistiche(p, s.gruppo)
	local partite = st.partite or 0
	local numeri = {
		{ migliaia(partite), "PARTITE" },
		{ partite > 0 and (math.floor((st.vinte or 0) * 100 / partite + 0.5) .. "%") or "–", "VINTE" },
		{ (st.colpi or 0) > 0 and (math.floor((st.a_segno or 0) * 100 / st.colpi + 0.5) .. "%") or "–", "PRECISIONE" },
		{ tostring(st.serie or 0), "SERIE MIGLIORE" },
	}
	for i, n in ipairs(numeri) do
		local nx = 44 + (i - 1) * 150
		titolo(n[1], nx, 548, 1, C.LUCE, parent, gui.PIVOT_W)
		testo(n[2], nx + 2, 516, 0.55, C.SPENTO, parent, gui.PIVOT_W)
	end
	testo("tocca un badge per metterlo accanto al tuo nome (al massimo " .. traguardi.MOSTRATI .. ")", 1236, 516, 0.55,
		C.SPENTO, parent, gui.PIVOT_E)

	-- le statistiche coi badge
	local tutte = profilo.statistiche(p, "tutte")
	local scelti = {}
	for _, id in ipairs(p.badge) do scelti[id] = true end
	local pan = ui.pannello(432, 252, 800, 456, parent)
	for i, t in ipairs(traguardi.LISTA) do
		local y = 200 - (i - 1) * 49
		local val = st[t.id] or 0
		if i > 1 then box(0, y + 24, 760, 1.5, con_alfa(C.LUCE, 0.1), pan) end
		testo(t.nome, -380, y, 0.8, C.TESTO, pan, gui.PIVOT_W)
		testo(migliaia(val) .. (t.unita and (" " .. t.unita) or ""), -110, y, 0.8, C.LUCE, pan, gui.PIVOT_E)
		if t.soglie then
			-- il badge viene dal totale di tutti i modi
			local tot = tutte[t.id] or 0
			local g = traguardi.grado(t, tot)
			if g > 0 then
				cartellino.badge({ id = t.id, grado = g }, -80, y, 28, pan)
				zona(s, -80, y + 0, 760, 46, "badge:" .. t.id, pan)
			end
			local prossima, quanto = traguardi.prossima(t, tot)
			local b = ui.barra(70, y, 220, 8, C.ORO, pan)
			ui.barra_valore(b, quanto)
			local dx = scelti[t.id] and g > 0 and "ACCANTO AL NOME" or
				(prossima and ("prossimo a " .. migliaia(prossima)) or (t.badge .. " " .. ROMANI[g]))
			testo(dx, 380, y, 0.55, scelti[t.id] and g > 0 and C.ORO or C.SPENTO, pan, gui.PIVOT_E)
		else
			testo("senza badge", 380, y, 0.55, C.SPENTO, pan, gui.PIVOT_E)
		end
	end

	-- il danno per arma
	local dan = ui.pannello(1050, 252, 396, 456, parent)
	titolo("DANNO PER ARMA", -176, 196, 0.55, C.LUCE, dan, gui.PIVOT_W)
	testo("quanto del tuo danno, arma per arma", -176, 168, 0.55, C.SPENTO, dan, gui.PIVOT_W)
	local armi, tot = {}, 0
	for w, n in pairs(st.armi or {}) do
		armi[#armi + 1] = { w = w, n = n }
		tot = tot + n
	end
	table.sort(armi, function(a, b)
		if a.n ~= b.n then return a.n > b.n end
		return a.w < b.w
	end)
	if #armi == 0 then testo("ancora niente: gioca una partita", -176, 110, 0.7, C.SPENTO, dan, gui.PIVOT_W) end
	local primo = armi[1] and armi[1].n or 1
	for i, a in ipairs(armi) do
		if i > 7 then break end
		local y = 120 - (i - 1) * 50
		testo(ARMI[a.w] or a.w, -176, y, 0.8, C.TESTO, dan, gui.PIVOT_W)
		local b = ui.barra(40, y, 160, 12, game.SECONDARY[a.w] and C.ACCIAIO or C.BRACE, dan)
		ui.barra_valore(b, a.n / primo)
		testo(math.floor(a.n * 100 / tot + 0.5) .. "%", 176, y, 0.8, C.LUCE, dan, gui.PIVOT_E)
	end
end

-- Scheda PARTITE --------------------------------------------------------------------

local function quando(t)
	if not t then return "" end
	local ora = os.time()
	local oggi = os.date("*t", ora)
	local d = os.date("*t", t)
	if d.year == oggi.year and d.yday == oggi.yday then return os.date("oggi %H:%M", t) end
	if d.year == oggi.year and d.yday == oggi.yday - 1 then return os.date("ieri %H:%M", t) end
	return os.date("%d/%m %H:%M", t)
end

local ESITO = { V = { "VINTA", C.MENTA }, S = { "PERSA", C.BRACE }, P = { "PARI", C.LUCE } }

local function faccina(v, x, y, d, parent)
	local col = C.SQUADRA[v.squadra] or C.LUCE
	ui.disco(x, y, d, C.FONDO, parent)
	local img = require("battaglia.pelli").pelli.gabriella_squadra.pezzi.testa
	local k = (d * 1.1) / img.h
	local n = box(x, y - d * 0.08, img.w * k, img.h * k, vmath.vector4(1, 1, 1, 1), parent)
	gui.set_texture(n, "diavoletto")
	gui.play_flipbook(n, img.img)
	ui.anello(x, y, d, 2.5, col, parent)
end

-- la fune: il vantaggio della tua squadra a ogni giro
local function fune(valori, cx, cy, w, h, parent, mio, altro)
	box(cx, cy + h / 4, w, h / 2, con_alfa(mio, 0.07), parent)
	box(cx, cy - h / 4, w, h / 2, con_alfa(altro, 0.07), parent)
	box(cx, cy, w, 1.5, con_alfa(C.LUCE, 0.35), parent)
	local max = 50
	for _, v in ipairs(valori) do max = math.max(max, math.abs(v)) end
	local n = #valori
	local function punto(i)
		local px = cx - w / 2 + (n > 1 and (i - 1) * w / (n - 1) or w / 2)
		return px, cy + valori[i] / max * (h / 2 - 8)
	end
	for i = 2, n do
		local x1, y1 = punto(i - 1)
		local x2, y2 = punto(i)
		local dx, dy = x2 - x1, y2 - y1
		local seg = box((x1 + x2) / 2, (y1 + y2) / 2, math.sqrt(dx * dx + dy * dy), 3, C.LUCE, parent)
		gui.set_euler(seg, vmath.vector3(0, 0, math.deg(math.atan2(dy, dx))))
	end
	for i = 1, n do
		local x, y = punto(i)
		ui.disco(x, y, i == n and 13 or 9, valori[i] >= 0 and mio or altro, parent)
		if i > 1 then
			testo(i == n and "FINE" or ("giro " .. (i - 1)), x, cy - h / 2 - 12, 0.45, C.SPENTO, parent)
		end
	end
	testo("+" .. migliaia(max), cx - w / 2 - 8, cy + h / 2 - 10, 0.45, mio, parent, gui.PIVOT_E)
	testo("−" .. migliaia(max), cx - w / 2 - 8, cy - h / 2 + 10, 0.45, altro, parent, gui.PIVOT_E)
end

local function scheda_partite(s, parent)
	local p = s.prof
	testo("LE ULTIME " .. profilo.PARTITE .. " · I REPLAY DI QUELLE GIOCATE SU QUESTO TELEFONO", 44, 612, 0.6, C.SPENTO,
		parent, gui.PIVOT_W)
	if #p.partite == 0 then
		testo("Nessuna partita ancora: gioca, e la ritrovi qui.", 640, 360, 1, C.SPENTO, parent)
		return
	end
	s.scelta = math.min(s.scelta or 1, #p.partite)
	for i, pa in ipairs(p.partite) do
		local y = 568 - (i - 1) * 54
		local e = ESITO[pa.esito] or ESITO.P
		local sel = i == s.scelta
		local riga = box(302, y, 540, 50, sel and con_alfa(C.LUCE, 0.06) or con_alfa(C.LUCE, 0), parent)
		if sel then
			local f, bo = ui.pannello(0, 0, 540, 50, riga)
			gui.set_color(f, con_alfa(C.FONDO, 0))
			gui.set_color(bo, C.LUCE)
		end
		box(-266, 0, 6, 46, e[2], riga)
		titolo(e[1], -252, 0, 0.5, e[2], riga, gui.PIVOT_W)
		local mappa = maps.get(pa.mappa or "")
		testo((mappa and mappa.name or "?") .. " · " .. (profilo.NOMI_GRUPPI[pa.gruppo] or pa.gruppo or ""), -150, 9, 0.62,
			C.LUCE, riga, gui.PIVOT_W)
		testo(quando(pa.quando), -150, -12, 0.5, C.SPENTO, riga, gui.PIVOT_W)
		for k, g in ipairs(pa.giocatori or {}) do
			if k > 4 then break end
			faccina(g, 120 + (k - 1) * 30, 0, 26, riga)
		end
		local diff = (pa.punti[1] or 0) - (pa.punti[2] or 0)
		testo((diff > 0 and "+" or diff < 0 and "−" or "") .. migliaia(math.abs(diff)), 258, 0, 0.75, C.LUCE, riga, gui.PIVOT_E)
		zona(s, 302, y, 540, 50, "partita:" .. i, parent)
	end

	-- la partita scelta
	local pa = p.partite[s.scelta]
	local pan = ui.pannello(920, 318, 656, 588, parent)
	local e = ESITO[pa.esito] or ESITO.P
	local mio = C.SQUADRA[(pa.giocatori[pa.me or 1] or {}).squadra or 1] or C.SQUADRA[1]
	local altro = C.SQUADRA[2]
	for _, g in ipairs(pa.giocatori or {}) do
		if g.squadra ~= (pa.giocatori[pa.me or 1] or {}).squadra then altro = C.SQUADRA[g.squadra] or altro end
	end
	titolo(e[1], -306, 262, 0.75, e[2], pan, gui.PIVOT_W)
	local mappa = maps.get(pa.mappa or "")
	testo((mappa and mappa.name or "?") .. " · " .. (profilo.NOMI_GRUPPI[pa.modo] or profilo.NOMI_GRUPPI[pa.gruppo] or ""),
		-180, 258, 0.8, C.LUCE, pan, gui.PIVOT_W)
	local pt = titolo(migliaia(pa.punti[2] or 0), 306, 262, 0.6, altro, pan, gui.PIVOT_E)
	local wpt = resource.get_text_metrics(gui.get_font_resource(gui.get_font(pt)), gui.get_text(pt)).width * 0.6
	testo("–", 306 - wpt - 12, 262, 0.8, C.SPENTO, pan)
	titolo(migliaia(pa.punti[1] or 0), 306 - wpt - 24, 262, 0.6, mio, pan, gui.PIVOT_E)
	testo("COM'È ANDATA, GIRO PER GIRO", -306, 222, 0.55, C.SPENTO, pan, gui.PIVOT_W)
	fune(pa.fune or { 0 }, 20, 120, 560, 160, pan, mio, altro)
	testo("MOMENTI · TOCCA PER RIVEDERLO DA LÌ", -306, 6, 0.55, C.SPENTO, pan, gui.PIVOT_W)
	local ok = s.replay_ok and s.replay_ok(pa.numero)
	local momenti = pa.momenti or {}
	if #momenti == 0 then testo("nessun momento da ricordare", -306, -30, 0.65, C.SPENTO, pan, gui.PIVOT_W) end
	for i, m in ipairs(momenti) do
		if i > 4 then break end
		local mx = -156 + ((i - 1) % 2) * 316
		local my = -34 - math.floor((i - 1) / 2) * 46
		local c, bordo = ui.pannello(mx, my, 304, 40, pan)
		if not ok then gui.set_color(bordo, con_alfa(C.LUCE, 0.12)) end
		testo(m.giro, -140, 0, 0.5, C.SPENTO, c, gui.PIVOT_W)
		testo(m.testo, -84, 0, 0.6, ok and C.TESTO or C.SPENTO, c, gui.PIVOT_W)
		if ok then
			s.bottoni[#s.bottoni + 1] = { nodo = c, bordo = bordo, azione = "momento:" .. i, colore = C.LUCE,
				riposo = gui.get_color(bordo) }
		end
	end
	-- chi c'era: toccandolo, il suo cartellino di quella volta
	for k, g in ipairs(pa.giocatori or {}) do
		if k > 4 then break end
		local gx = -296 + (k - 1) * 150
		faccina(g, gx + 20, -158, 40, pan)
		testo(g.nome or "?", gx + 46, -150, 0.55, C.TESTO, pan, gui.PIVOT_W)
		testo(g.livello and ("LIV " .. g.livello) or (g.bot and "BOT" or ""), gx + 46, -168, 0.45, C.SPENTO, pan,
			gui.PIVOT_W)
		zona(s, gx + 60, -158, 140, 46, "giocatore:" .. k, pan)
	end
	if ok then
		ui.bottone(s.bottoni, 210, -246, 200, 58, "RIVEDI", "rivedi", { principale = true, colore = mio }, pan)
	else
		testo(pa.online and "replay solo delle partite su questo telefono" or "replay non disponibile",
			306, -246, 0.6, C.SPENTO, pan, gui.PIVOT_E)
	end
end

-- Schermata ---------------------------------------------------------------------------

local function costruisci(s)
	if s.radice then gui.delete_node(s.radice) end
	for _, n in ipairs(s.angoli or {}) do gui.delete_node(n) end
	s.bottoni, s.figura = {}, nil
	local p = s.prof
	-- indietro e livello si attaccano ai bordi veri (ui/schermo.lua): solo un
	-- nodo senza genitore si attacca, quindi stanno fuori dalla radice, e
	-- prima di lei, così il velo del cartellino aperto li copre
	local indietro = ui.indietro(s.bottoni, "indietro")
	local dx = gui.new_box_node(vec(W - 44, 680), vec(0, 0))
	s.angoli = { indietro, dx }
	s.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(s.radice, false)
	ui.scheda(s.bottoni, 400, 662, 150, 56, "SCHEDA", "scheda:scheda", s.scheda == "scheda", s.radice)
	ui.scheda(s.bottoni, 586, 662, 206, 56, "STATISTICHE", "scheda:statistiche", s.scheda == "statistiche", s.radice)
	ui.scheda(s.bottoni, 772, 662, 150, 56, "PARTITE", "scheda:partite", s.scheda == "partite", s.radice)
	-- livello ed esperienza in alto a destra
	gui.set_visible(dx, false)
	gui.set_xanchor(dx, gui.ANCHOR_RIGHT)
	gui.set_yanchor(dx, gui.ANCHOR_TOP)
	titolo("LIV " .. p.livello, 0, 0, 0.55, C.LUCE, dx, gui.PIVOT_E)
	local b = ui.barra(-130, -24, 260, 8, s.colore, dx)
	ui.barra_valore(b, p.xp / profilo.xp_livello(p.livello))
	testo(migliaia(p.xp) .. " / " .. migliaia(profilo.xp_livello(p.livello)) .. " XP", 0, -42, 0.5, C.SPENTO, dx, gui.PIVOT_E)
	if s.scheda == "statistiche" then
		scheda_statistiche(s, s.radice)
	elseif s.scheda == "partite" then
		scheda_partite(s, s.radice)
	else
		scheda_scheda(s, s.radice)
	end
	if s.aperto then
		-- il cartellino di un giocatore di una partita passata, sopra a tutto
		s.velo = box(W / 2, H / 2, W * 4, H * 4, con_alfa(C.FONDO, 0.82), s.radice)
		local v = s.aperto
		v.verso = 1
		s.carta = cartellino.new(v, W / 2, 360 + cartellino.ALTO({ ritratto = true }) / 2, { ritratto = true, tu = v.tu }, s.radice)
	else
		s.carta = nil
	end
end

function M.new(prof, scheda, colore, replay_ok, numero)
	local s = { prof = prof, scheda = scheda or "scheda", colore = colore or C.SQUADRA[1], replay_ok = replay_ok }
	-- le statistiche partono dal modo dell'ultima partita (dal 2 contro 2 se non ce n'è)
	local ultimo = prof.partite[1] and prof.partite[1].gruppo or "2v2"
	s.gruppo = "tutte"
	for _, g in ipairs(profilo.GRUPPI) do
		if g == ultimo then s.gruppo = g end
	end
	-- numero: la partita da mostrare nella scheda PARTITE (tornando da un replay)
	for i, pa in ipairs(prof.partite) do
		if pa.numero == numero then s.scelta = i end
	end
	s.fondo = ui.sfondo()
	costruisci(s)
	return s
end

function M.update(s, dt)
	if s.figura then scoria.update(s.figura, dt, s.st) end
	if s.carta then cartellino.update(s.carta, dt) end
end

local function esegui(s, azione)
	local tipo, x = azione:match("^(%a+):?(.*)$")
	local p = s.prof
	if tipo == "scheda" then
		s.scheda = x
	elseif tipo == "assetto" then
		p.attivo = tonumber(x)
		profilo.salva(p)
	elseif tipo == "gruppo" then
		s.gruppo = x
	elseif tipo == "badge" then
		profilo.scegli_badge(p, x)
		profilo.salva(p)
	elseif tipo == "partita" then
		s.scelta = tonumber(x)
	elseif tipo == "giocatore" then
		local pa = p.partite[s.scelta or 1]
		s.aperto = pa and pa.giocatori[tonumber(x)]
	elseif tipo == "momento" then
		local pa = p.partite[s.scelta or 1]
		local m = pa and pa.momenti[tonumber(x)]
		-- un attimo prima, per vedere come ci si arriva
		if m then return { rivedi = pa.numero, da = math.max(0, m.t - 180) } end
	elseif tipo == "rivedi" then
		local pa = p.partite[s.scelta or 1]
		if pa then return { rivedi = pa.numero, da = 0 } end
	end
	costruisci(s)
end

function M.on_input(s, action_id, action)
	-- il cartellino aperto: un tocco qualsiasi lo chiude
	if s.aperto then
		if (action_id == TOUCH and action.pressed) or (action_id == ui.PAD and action.pressed) then
			s.aperto = nil
			costruisci(s)
		end
		return nil
	end
	local azione = ui.tocco(s.bottoni, action_id, action)
	if azione == "indietro" or azione == "armeria" then return azione end
	if azione then return esegui(s, azione) end
	return nil
end

function M.distruggi(s)
	for _, n in ipairs(s.angoli or {}) do gui.delete_node(n) end
	gui.delete_node(s.radice)
	gui.delete_node(s.fondo)
end

return M
