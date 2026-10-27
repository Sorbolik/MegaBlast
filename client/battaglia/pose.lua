-- Le clip delle animazioni del diavoletto (battaglia/animazioni.lua, fatte con
-- l'editor strumenti/animazioni/editor.html): fotogrammi chiave per canale,
-- campionati a un tempo qualsiasi, così il movimento è fluido a ogni frequenza.
--
-- Una clip: { durata = secondi, ciclo = true se ricomincia, tracce = { canale =
-- { t, v, curva, t, v, curva, ... } }, viso = { t, "faccia", ... } }. La curva
-- dice come si va dalla chiave alla successiva: 0 liscia, 1 dritta, 2 a scatto.
-- I canali che una clip non ha restano neutri.
--
-- Più clip si sommano in una posa con un peso (la corsa che sfuma nel fermo, il
-- salto che sale o scende): ognuna aggiunge peso * (valore - neutro).
--   local posa = pose.nuova()
--   pose.azzera(posa); pose.aggiungi(posa, clip, t, peso)   -- nessuna allocazione

local M = {}

-- i canali e il loro valore neutro; angoli in radianti, misure in unità del
-- disegno (battaglia/diavoletto.lua, 200 dai piedi alla testa)
M.CANALI = { "corpo", "salto", "schiaccia", "testa", "testa_y", "braccio_a", "braccio_d",
	"gamba_a", "gamba_d", "alza_a", "alza_d", "ala", "coda" }
M.NEUTRO = { schiaccia = 1 }
for _, c in ipairs(M.CANALI) do M.NEUTRO[c] = M.NEUTRO[c] or 0 end

local floor = math.floor

function M.nuova()
	local p = { viso = nil, peso_viso = 0 }
	M.azzera(p)
	return p
end

function M.azzera(p)
	for c, v in pairs(M.NEUTRO) do p[c] = v end
	p.viso, p.peso_viso = nil, 0
end

-- il tempo dentro la clip: in ciclo gira, altrimenti si ferma alla fine
local function dentro(clip, t)
	local d = clip.durata
	if clip.ciclo then return t - floor(t / d) * d end
	return t < 0 and 0 or (t > d and d or t)
end

-- la pendenza in una chiave (i: indice della chiave, da 0), dalle vicine: per
-- la curva liscia (Catmull-Rom). Agli estremi di una clip che non gira è
-- piatta, così parte e arriva piano
local function pendenza(tr, i, n, d, ciclo)
	local ta, va, tb, vb
	if i > 0 then
		ta, va = tr[3 * i - 2], tr[3 * i - 1]
	elseif ciclo and n > 1 then
		ta, va = tr[3 * n - 2] - d, tr[3 * n - 1]
	else
		return 0
	end
	if i < n - 1 then
		tb, vb = tr[3 * i + 4], tr[3 * i + 5]
	elseif ciclo and n > 1 then
		tb, vb = tr[1] + d, tr[2]
	else
		return 0
	end
	if tb - ta < 1e-9 then return 0 end
	return (vb - va) / (tb - ta)
end

-- il valore di una traccia al tempo t (già dentro la clip)
function M.valore(tr, t, d, ciclo)
	local n = #tr / 3
	if n == 1 then return tr[2] end
	-- la chiave prima di t (i, da 0) e quella dopo (j); in ciclo, prima della
	-- prima chiave si viene dall'ultima del giro prima
	local i = -1
	for k = 0, n - 1 do
		if tr[3 * k + 1] <= t then i = k else break end
	end
	local t0, t1, j
	if i < 0 then
		if not ciclo then return tr[2] end
		i, j = n - 1, 0
		t0, t1 = tr[3 * n - 2] - d, tr[1]
	elseif i == n - 1 then
		if not ciclo then return tr[3 * n - 1] end
		j = 0
		t0, t1 = tr[3 * i + 1], tr[1] + d
	else
		j = i + 1
		t0, t1 = tr[3 * i + 1], tr[3 * j + 1]
	end
	local v0, v1, curva = tr[3 * i + 2], tr[3 * j + 2], tr[3 * i + 3]
	local h = t1 - t0
	if curva == 2 or h < 1e-9 then return v0 end
	local u = (t - t0) / h
	if curva == 1 then return v0 + (v1 - v0) * u end
	local m0, m1 = pendenza(tr, i, n, d, ciclo) * h, pendenza(tr, j, n, d, ciclo) * h
	local u2, u3 = u * u, u * u * u
	return (2 * u3 - 3 * u2 + 1) * v0 + (u3 - 2 * u2 + u) * m0 + (-2 * u3 + 3 * u2) * v1 + (u3 - u2) * m1
end

-- aggiunge alla posa la clip al tempo t, col suo peso
function M.aggiungi(p, clip, t, peso)
	if peso <= 0 then return end
	t = dentro(clip, t)
	local d, ciclo = clip.durata, clip.ciclo
	for c, tr in pairs(clip.tracce) do
		p[c] = p[c] + peso * (M.valore(tr, t, d, ciclo) - M.NEUTRO[c])
	end
	local viso = clip.viso
	if viso and peso > p.peso_viso then
		-- la faccia va a scatti: l'ultima chiave non dopo t (prima della prima,
		-- in ciclo, l'ultima del giro prima)
		local f = ciclo and viso[#viso] or viso[2]
		for k = 1, #viso, 2 do
			if viso[k] <= t then f = viso[k + 1] else break end
		end
		p.viso, p.peso_viso = f, peso
	end
end

return M
