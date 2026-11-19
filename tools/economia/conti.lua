-- I conti dell'economia (Sergio, 17 nov): quante ORE di gioco servono per ogni
-- traguardo, calcolate dai numeri veri del gioco (premi di una partita, costi dei
-- pezzi, esperienza dei livelli), per un giocatore forte e per uno medio.
-- Si ragiona sempre in ore, mai in partite al giorno. Dalla radice:
--   luajit tools/economia/conti.lua              (stampa la tabella)
--   luajit tools/economia/conti.lua --controlla  (fallisce se un traguardo esce dai tempi decisi: gira in tutti.sh)
-- Se cambi premi o costi e il controllo fallisce: o ritari, o Sergio decide tempi
-- nuovi e si cambiano qui sotto in TEMPI.
package.path = "client/?.lua;" .. package.path

local equip = require "sim.gear"
local wallet = require "sim.wallet"
local profile = require "menu.profile"
local awards = require "sim.awards"

-- partite in un'ora (misurate: una partita online dura circa 6 minuti con l'attesa)
local PARTITE_ORA = 10
-- ore di gioco al giorno (per il premio della prima vittoria)
local ORE_GIORNO = 2

-- chi gioca: quanto vince, i punti di una partita, quanto spesso è il migliore, i premi
local GIOCATORI = {
	-- (il forte è il caso che i conti non devono mai sottovalutare: vince quasi
	-- sempre da migliore, coi punti al massimo e due premi)
	{ nome = "forte", vince = 0.9, punti = 240, migliore = 0.9, premi = 2 },
	{ nome = "medio", vince = 0.5, punti = 90, migliore = 0.25, premi = 0 },
}

-- i tempi decisi da Sergio (17 nov), in ore del giocatore forte: { da, a }; coi
-- guanti (19 nov) un pezzo costa il 20% in meno, cinque pezzi nel tempo di quattro
local TEMPI = {
	primo_scatto = { 3, 8 },
	pezzo = { 64, 96 },
	livello_max = { 200, 280 },
}

local function somma(righe, campo)
	local n = 0
	for _, r in ipairs(righe) do n = n + (r[campo] or 0) end
	return n
end

-- una partita online: Scaglie, esperienza e Ossidiana (senza la prima vittoria del giorno)
local function partita(r)
	local p = profile.new()
	p.giorno = "x"
	local righe, oss = wallet.match(p, r, "x")
	return somma(righe, "scaglie"), profile.match_end(profile.new(), r).xp, somma(oss, "ossidiana")
end

-- una partita di allenamento (contro i bot o sullo stesso telefono): metà di
-- tutto, niente Ossidiana, e solo le prime wallet.BOTS_DAY del giorno
local function allenamento(r)
	local p = profile.new()
	r.bots = true
	local xp = profile.match_end(p, r, "x").xp
	return somma((wallet.match(p, r, "x")), "scaglie"), xp
end

-- quello che entra in un'ora
local function ora(g)
	local s, x, o = 0, 0, 0
	local lista = {}
	for i = 1, g.premi do lista[i] = awards.LIST[i] end
	-- i quattro casi: vinta o persa, migliore o no
	for _, c in ipairs({ { true, true }, { true, false }, { false, true }, { false, false } }) do
		local quota = (c[1] and g.vince or 1 - g.vince) * (c[2] and g.migliore or 1 - g.migliore)
		local cs, cx, co = partita({ points = g.punti, won = c[1], mvp = c[2], awards = lista })
		s, x, o = s + quota * cs, x + quota * cx, o + quota * co
	end
	s, x, o = s * PARTITE_ORA, x * PARTITE_ORA, o * PARTITE_ORA
	-- la prima vittoria del giorno, spalmata sulle ore di un giorno
	s = s + wallet.DAILY / ORE_GIORNO
	o = o + wallet.OBS_DAILY / ORE_GIORNO
	return s, x, o
end

local function costo_pezzo(fino)
	local n = 0
	for l = 2, fino do n = n + equip.cost(l) end
	return n
end

local function xp_fino(livello)
	local n = 0
	for l = 1, livello - 1 do n = n + profile.xp_level(l) end
	return n
end

local firma = 0
for _, c in ipairs(equip.SIGN_COSTS) do firma = firma + c end
local posti, pezzi = #equip.SLOTS, 0
for _, f in ipairs(equip.SETS) do
	for _, s in ipairs(equip.SLOTS) do
		if f.pieces[s.id] then pezzi = pezzi + 1 end
	end
end

local controlla = arg[1] == "--controlla"
local falliti = {}
for _, g in ipairs(GIOCATORI) do
	local s, x, o = ora(g)
	local righe = {
		{ "primo_scatto", "un pezzo al primo scatto (livello 10)", costo_pezzo(10) / s },
		{ "pezzo", "un pezzo al livello " .. equip.LIVELLO_MAX, costo_pezzo(equip.LIVELLO_MAX) / s },
		{ "set", posti .. " pezzi al massimo (quelli addosso)", posti * costo_pezzo(equip.LIVELLO_MAX) / s },
		{ "tutti", "tutti i " .. pezzi .. " pezzi al massimo", pezzi * costo_pezzo(equip.LIVELLO_MAX) / s },
		{ "bottega", "un pezzo del giorno in Bottega", wallet.PRICE_CATALOG / s },
		{ "livello_max", "livello " .. profile.LEVEL_MAX, xp_fino(profile.LEVEL_MAX) / x },
		{ "firma", "una firma tutta accesa (" .. firma .. " Ossidiana)", firma / o },
		{ "firme", "le firme dei " .. posti .. " pezzi addosso", posti * firma / o },
	}
	if not controlla then
		print(string.format("Giocatore %s: in un'ora %d Scaglie, %d esperienza, %.1f Ossidiana", g.nome, s, x, o))
		for _, r in ipairs(righe) do print(string.format("  %-46s %7.1f ore", r[2], r[3])) end
		local as, ax = allenamento({ points = g.punti, won = true, mvp = true })
		print(string.format("  in allenamento, una vittoria da migliore: %d Scaglie e %d esperienza (solo le prime %d partite del giorno: al massimo %d e %d)",
			as, ax, wallet.BOTS_DAY, as * wallet.BOTS_DAY, ax * wallet.BOTS_DAY))
	end
	if g.nome == "forte" then
		for _, r in ipairs(righe) do
			local t = TEMPI[r[1]]
			if t and (r[3] < t[1] or r[3] > t[2]) then
				falliti[#falliti + 1] = string.format("%s: %.1f ore, deciso fra %d e %d", r[2], r[3], t[1], t[2])
			end
		end
	end
end
if #falliti > 0 then
	print("I tempi dell'economia non tornano (tools/economia/conti.lua):")
	for _, f in ipairs(falliti) do print("  " .. f) end
	os.exit(1)
end
if controlla then print("OK") end
