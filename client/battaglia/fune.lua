-- La fune del Rampino nel disegno: un filo d'acciaio a pezzi con l'uncino in
-- punta (strumenti/grafica/armi.py). Vola dritto dalla mano all'uncino mentre
-- si allunga, resta tesa finché tira, sfuma quando molla; se l'uncino non prende
-- niente, uncino e filo cadono insieme (corda a punti, Verlet) e si dissolvono.
-- Solo grafica: la fisica del Rampino è in sim/game.lua.
--
--   local f = fune.nuova(K)           -- K: spessore del filo (unità del mondo per 1,5)
--   fune.nodi(f)                      -- i nodi da mettere nel mondo
--   fune.dritta(f, x0, y0, x1, y1)    -- dalla mano (x0, y0) all'uncino (x1, y1)
--   fune.sfuma(f)                     -- tesa che molla: sparisce in un attimo
--   fune.cade(f, x0, y0, x1, y1)      -- andata a vuoto: cade col filo
--   fune.update(f, dt, solido)        -- la caduta (solido(x, y): c'è terreno lì); false quando non si vede più
--   f.stato: nil (non si vede), "dritta", "sfuma", "cade"

local UNCINO = require("battaglia.armi").pezzi.uncino

local M = {}

local PEZZI = 12        -- pezzi del filo
local GRAVITA = 900     -- della caduta, in unità del mondo al secondo²
local RESTA = 0.35      -- secondi prima che cominci a dissolversi
local SVANISCE = 0.5    -- secondi per dissolversi
local SFUMA = 0.25
local ACCIAIO = vmath.vector4(0.6, 0.63, 0.67, 1)
-- l'uncino in volo, un po' più grande che in canna: si deve leggere
local GRANDE = 1.25

local V3 = vmath.vector3(0, 0, 0)
local EUL = vmath.vector3(0, 0, 0)

local function fit(n)
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	return n
end

function M.nuova(k)
	local f = { pezzi = {}, x = {}, y = {}, px = {}, py = {}, t = 0, spessore = 1.5 * k, col = vmath.vector4(ACCIAIO),
		col_img = vmath.vector4(1, 1, 1, 1) }
	for i = 1, PEZZI do
		local n = fit(gui.new_box_node(V3, V3))
		gui.set_color(n, f.col)
		gui.set_enabled(n, false)
		f.pezzi[i] = n
	end
	local u = UNCINO
	-- il perno dell'uncino è l'anello (l'origine del disegno), dove arriva il filo
	f.uncino = fit(gui.new_box_node(V3, V3))
	gui.set_visible(f.uncino, false)
	gui.set_enabled(f.uncino, false)
	local img = fit(gui.new_box_node(vmath.vector3(u.x * GRANDE, u.y * GRANDE, 0), vmath.vector3(u.w * GRANDE, u.h * GRANDE, 0)))
	gui.set_texture(img, "armi")
	gui.play_flipbook(img, u.img)
	gui.set_parent(img, f.uncino)
	f.img = img
	for i = 0, PEZZI do f.x[i], f.y[i], f.px[i], f.py[i] = 0, 0, 0, 0 end
	return f
end

function M.nodi(f)
	local out = {}
	for i = 1, PEZZI do out[i] = f.pezzi[i] end
	out[#out + 1] = f.uncino
	return out
end

local function alfa(f, a)
	f.col.w = a
	for i = 1, PEZZI do gui.set_color(f.pezzi[i], f.col) end
	f.col_img.w = a
	gui.set_color(f.img, f.col_img)
end

local function mostra(f, on)
	if f.on == on then return end
	f.on = on
	for i = 1, PEZZI do gui.set_enabled(f.pezzi[i], on) end
	gui.set_enabled(f.uncino, on)
end

-- disegna il filo dai punti x[0..PEZZI], y[...] e l'uncino in punta
local function disegna(f)
	for i = 1, PEZZI do
		local x0, y0, x1, y1 = f.x[i - 1], f.y[i - 1], f.x[i], f.y[i]
		local dx, dy = x1 - x0, y1 - y0
		local n = f.pezzi[i]
		V3.x, V3.y = (x0 + x1) / 2, (y0 + y1) / 2
		gui.set_position(n, V3)
		-- un filo di pezzi: ognuno un po' più lungo, così non si vedono le giunture
		V3.x, V3.y = math.sqrt(dx * dx + dy * dy) + f.spessore * 0.5, f.spessore
		gui.set_size(n, V3)
		EUL.z = math.deg(math.atan2(dy, dx))
		gui.set_euler(n, EUL)
	end
	local n = PEZZI
	V3.x, V3.y = f.x[n], f.y[n]
	gui.set_position(f.uncino, V3)
	EUL.z = math.deg(math.atan2(f.y[n] - f.y[n - 1], f.x[n] - f.x[n - 1]))
	gui.set_euler(f.uncino, EUL)
end

local function dritti(f, x0, y0, x1, y1)
	for i = 0, PEZZI do
		f.x[i], f.y[i] = x0 + (x1 - x0) * i / PEZZI, y0 + (y1 - y0) * i / PEZZI
	end
end

function M.dritta(f, x0, y0, x1, y1)
	f.stato = "dritta"
	alfa(f, 1)
	mostra(f, true)
	-- tesa: l'uncino non si gira se la fune è cortissima
	if (x1 - x0) ^ 2 + (y1 - y0) ^ 2 < 1 then x0 = x1 - 1 end
	dritti(f, x0, y0, x1, y1)
	disegna(f)
end

function M.sfuma(f)
	if f.stato ~= "dritta" then return end
	f.stato, f.t = "sfuma", 0
end

-- L'uncino non ha preso niente: filo e uncino cadono insieme, la punta (più
-- pesante) continua un poco nel verso in cui volava
function M.cade(f, x0, y0, x1, y1)
	f.stato, f.t = "cade", 0
	alfa(f, 1)
	mostra(f, true)
	dritti(f, x0, y0, x1, y1)
	local d = math.sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2)
	f.lungo = d / PEZZI
	local ux, uy = d > 0 and (x1 - x0) / d or 0, d > 0 and (y1 - y0) / d or 0
	-- velocità iniziale (in punti di prima): avanti, di più verso la punta
	for i = 0, PEZZI do
		local v = 3 * i / PEZZI
		f.px[i], f.py[i] = f.x[i] - ux * v, f.y[i] - uy * v
	end
	disegna(f)
end

function M.update(f, dt, solido)
	if not f.stato then return false end
	if f.stato == "dritta" then return true end
	f.t = f.t + dt
	if f.stato == "sfuma" then
		local a = 1 - f.t / SFUMA
		if a <= 0 then
			f.stato = nil
			mostra(f, false)
			return false
		end
		alfa(f, a)
		return true
	end
	-- cade: Verlet con la gravità, poi la lunghezza di ogni pezzo
	local g = GRAVITA * dt * dt
	for i = 0, PEZZI do
		local x, y = f.x[i], f.y[i]
		f.x[i], f.y[i] = x + (x - f.px[i]) * 0.99, y + (y - f.py[i]) * 0.99 - g
		f.px[i], f.py[i] = x, y
	end
	for _ = 1, 3 do
		for i = 1, PEZZI do
			local dx, dy = f.x[i] - f.x[i - 1], f.y[i] - f.y[i - 1]
			local d = math.sqrt(dx * dx + dy * dy)
			if d > 0 then
				local c = (d - f.lungo) / d * 0.5
				f.x[i - 1], f.y[i - 1] = f.x[i - 1] + dx * c, f.y[i - 1] + dy * c
				f.x[i], f.y[i] = f.x[i] - dx * c, f.y[i] - dy * c
			end
		end
	end
	-- sul terreno il filo si appoggia: il punto che ci entra resta dov'era
	for i = 0, PEZZI do
		if solido(f.x[i], f.y[i]) then f.x[i], f.y[i] = f.px[i], f.py[i] end
	end
	disegna(f)
	if f.t > RESTA then
		local a = 1 - (f.t - RESTA) / SVANISCE
		if a <= 0 then
			f.stato = nil
			mostra(f, false)
			return false
		end
		alfa(f, a)
	end
	return true
end

return M
