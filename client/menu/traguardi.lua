-- Statistiche del giocatore e i loro badge (docs/roadmap.md, "Statistiche,
-- obiettivi e badge"; scheda personaggio, Sergio 31 ott). Lua puro: il profilo
-- le conta a fine partita (menu/profilo.lua, menu/conta.lua), la scheda
-- STATISTICHE le mostra (menu/profilo_schede.lua), il cartellino porta i badge
-- (ui/cartellino.lua).
--
-- Ogni statistica con un badge ha soglie che crescono di dieci volte in dieci
-- (10, 100, 1.000, 10.000): ogni soglia passata è un grado del badge (I..IV).
-- Il badge ha una forma (quale statistica) e il colore del grado.

local M = {}

-- Le statistiche, nell'ordine della scheda. id: la chiave nel profilo; nome: come
-- si legge; badge: il nome del badge (nil: senza); forma: cerchio, rombo,
-- esagono o stella; soglie: i gradi; record: si tiene il massimo, non la somma.
M.LISTA = {
	{ id = "nel_vuoto", nome = "Abbattuti nel vuoto", badge = "BECCHINO", forma = "rombo", soglie = { 10, 100, 1000, 10000 } },
	{ id = "abbattuti", nome = "Abbattuti", badge = "CACCIATORE", forma = "esagono", soglie = { 10, 100, 1000, 10000 } },
	{ id = "a_segno", nome = "Colpi a segno", badge = "MIRA", forma = "cerchio", soglie = { 10, 100, 1000, 10000 } },
	{ id = "danno", nome = "Danno fatto", badge = "MARTELLO", forma = "stella", soglie = { 1000, 10000, 100000, 1000000 } },
	{ id = "globi", nome = "Globi guadagnati", badge = "FULMINE", forma = "esagono", soglie = { 10, 100, 1000, 10000 } },
	{ id = "colpo_lungo", nome = "Colpo più lungo", badge = "LONTANO", forma = "stella", soglie = { 600, 900, 1200, 1500 },
		record = true, unita = "px" },
	{ id = "casse", nome = "Casse aperte", badge = "PREDONE", forma = "cerchio", soglie = { 10, 100, 1000, 10000 } },
	{ id = "vinte", nome = "Partite vinte", badge = "VINCITORE", forma = "rombo", soglie = { 10, 100, 1000, 10000 } },
	{ id = "cadute", nome = "Cadute" },
}
M.BY_ID = {}
for _, s in ipairs(M.LISTA) do M.BY_ID[s.id] = s end

-- Le altre voci contate (in alto nella scheda, o per calcolarne altre)
M.ALTRE = { "partite", "serie", "colpi", "morti", "teletrasporti" }

-- quanti badge si vedono accanto al nome
M.MOSTRATI = 3

-- grado del badge per il valore v (0: nessuno)
function M.grado(s, v)
	local g = 0
	for i, soglia in ipairs(s.soglie or {}) do
		if (v or 0) >= soglia then g = i end
	end
	return g
end

-- la prossima soglia e quanto ci manca, da 0 a 1 (dalla soglia di prima)
function M.prossima(s, v)
	v = v or 0
	local prima = 0
	for _, soglia in ipairs(s.soglie or {}) do
		if v < soglia then return soglia, math.max(0, (v - prima) / (soglia - prima)) end
		prima = soglia
	end
	return nil, 1
end

-- I badge presi con quei valori, dal grado più alto (a pari grado nell'ordine
-- della lista): { { id, grado }, ... }
function M.presi(valori)
	local out = {}
	for i, s in ipairs(M.LISTA) do
		local g = M.grado(s, valori[s.id])
		if g > 0 then out[#out + 1] = { id = s.id, grado = g, i = i } end
	end
	table.sort(out, function(a, b)
		if a.grado ~= b.grado then return a.grado > b.grado end
		return a.i < b.i
	end)
	for _, b in ipairs(out) do b.i = nil end
	return out
end

-- I badge da mostrare: quelli scelti (ancora presi), poi i più alti, fino a MOSTRATI
function M.mostrati(valori, scelti)
	local presi = M.presi(valori)
	local per_id = {}
	for _, b in ipairs(presi) do per_id[b.id] = b end
	local out, messi = {}, {}
	for _, id in ipairs(scelti or {}) do
		if per_id[id] and not messi[id] and #out < M.MOSTRATI then
			out[#out + 1] = per_id[id]
			messi[id] = true
		end
	end
	for _, b in ipairs(presi) do
		if #out >= M.MOSTRATI then break end
		if not messi[b.id] then
			out[#out + 1] = b
			messi[b.id] = true
		end
	end
	return out
end

-- Un badge arrivato da fuori (online, dagli altri): valido o nil
function M.valido(b)
	if type(b) ~= "table" then return nil end
	local s = M.BY_ID[b.id]
	local g = tonumber(b.grado)
	if not (s and s.soglie and g and g >= 1 and g <= #s.soglie and g % 1 == 0) then return nil end
	return { id = b.id, grado = g }
end

return M
