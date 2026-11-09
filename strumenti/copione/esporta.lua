-- Esporta per la pagina del Copione (prepara.py) i capitoli, i livelli così come
-- sono in client/sim/levels.lua e i cataloghi da cui la pagina fa scegliere
-- (armi, eventi, disegni delle vignette, facce, comandi, mappe). JSON su stdout.
-- Dalla radice: luajit strumenti/copione/esporta.lua
package.path = "client/?.lua;" .. package.path

local game = require "sim.game"
local campaign = require "sim.campaign"
local maps = require "sim.maps"
local it = require "lang.it"

-- l'ordine dei campi, come si leggono in levels.lua; gli altri in ordine alfabetico
local ORDINE = {}
for i, k in ipairs({ "id", "titolo", "tipo", "goal_text", "highlight", "guidata", "mappa", "arena", "spawns",
	"giocatori", "nascosti", "vita", "punti", "regrow", "vedi", "no_weapons", "without_time", "draft", "globi", "globi_tempo", "globi_lenti",
	"secondi", "al_tempo", "al_posto", "plans", "casse", "cards", "guida", "scintilla", "turni", "stelle",
	"medaglia", "obiettivo", "righe", "dimostra", "bravo", "bravo_faccia", "collaudo",
	-- dentro: giocatori, passi, righe, casse, guida
	"team", "bot", "dummy", "carattere", "pick", "secondary", "tool", "nome", "battute", "pelle", "insegna",
	"x", "y", "from", "w", "h", "t", "salto", "parte", "percorso",
	"reach", "flag", "prendi", "hit", "down", "usa", "win", "con", "come", "times", "globi", "only", "zoom", "nuova",
	"testo", "mostra", "faccia", "quando", "fino", "subito", "stops",
	"dopo", "arma", "give", "mosse", "cammina", "salta", "angolo", "potenza", "in_aria", "subito", "verso", "fino_a", "aspetta", "dice", "posa", "secondi" }) do
	ORDINE[k] = ORDINE[k] or i
end

local function lista(t)
	local n = 0
	for _ in pairs(t) do n = n + 1 end
	if n == 0 then return true end
	for i = 1, n do
		if t[i] == nil then return false end
	end
	return true
end

local function chiavi(t)
	local ks = {}
	for k in pairs(t) do ks[#ks + 1] = k end
	table.sort(ks, function(a, b)
		local oa, ob = ORDINE[a] or 1000, ORDINE[b] or 1000
		if type(a) == "number" and type(b) == "number" then return a < b end
		if oa ~= ob then return oa < ob end
		return tostring(a) < tostring(b)
	end)
	return ks
end

local function stringa(s)
	return '"' .. s:gsub('[%c"\\]', function(c)
		local e = { ['"'] = '\\"', ["\\"] = "\\\\", ["\n"] = "\\n", ["\t"] = "\\t" }
		return e[c] or string.format("\\u%04x", c:byte())
	end) .. '"'
end

local LISTE = {
	capitoli = true, livelli = true, spawns = true, giocatori = true, vedi = true,
	casse = true, cards = true, obiettivo = true, righe = true, dimostra = true,
	mosse = true, arena = true, draft = true, percorsi = true, stelle = true,
	nascosti = true, only = true, uno = true,
}

local function json(v, k_parent)
	local tv = type(v)
	if tv == "table" then
		local out = {}
		if lista(v) and next(v) ~= nil then
			for _, x in ipairs(v) do out[#out + 1] = json(x) end
			return "[" .. table.concat(out, ",") .. "]"
		end
		if next(v) == nil then
			if k_parent and LISTE[k_parent] then return "[]" end
			return "{}"
		end
		for _, k in ipairs(chiavi(v)) do out[#out + 1] = stringa(tostring(k)) .. ":" .. json(v[k], k) end
		return "{" .. table.concat(out, ",") .. "}"
	elseif tv == "string" then
		return stringa(v)
	elseif tv == "number" then
		return (v == math.floor(v) and string.format("%d", v)) or string.format("%.14g", v)
	elseif tv == "boolean" then
		return tostring(v)
	end
	error("non si esporta: " .. tv)
end

local function insieme(t)
	local l = {}
	for k in pairs(t) do l[#l + 1] = k end
	table.sort(l)
	return l
end

-- gli eventi (game:emit) e i disegni delle vignette, letti dai sorgenti
local eventi, disegni, facce = {}, {}, {}
for f in io.popen("ls client/sim/*.lua"):lines() do
	local h = assert(io.open(f))
	for tipo in h:read("*a"):gmatch('emit%(%{ type = "([%w_]+)"') do eventi[tipo] = true end
	h:close()
end
do
	local h = assert(io.open("client/battle/vignette.lua"))
	local src = h:read("*a")
	h:close()
	for nome in src:gmatch("\nDRAW%.([%w_]+) =") do disegni[nome] = true end
	for nome in src:match("M%.FACCE = (%b{})"):gmatch("([%w_]+) = true") do facce[nome] = true end
end

-- le clip delle animazioni: le pose che Favilla può fare quando mostra (dimostra)
local clip = {}
do
	local h = assert(io.open("client/battle/animations.lua"))
	for nome in h:read("*a"):gmatch("\n\t([%w_]+) = { duration") do clip[nome] = true end
	h:close()
end

local armi = {}
for w in pairs(game.WEAPONS) do
	armi[w] = { nome = it.hud.weapons[w] or w:upper(), secondaria = game.SECONDARY[w] or nil, attrezzo = game.TOOLS[w] or nil }
end

-- le mappe del gioco (non quelle delle missioni, che sono arene)
local mappe = {}
for id, def in pairs(maps.maps) do
	if not id:match("^missione_") then
		mappe[id] = { nome = def.name, spawns = def.spawns }
	end
end

local capitoli = {}
for _, cap in ipairs(campaign.CAPITOLI) do
	capitoli[#capitoli + 1] = { id = cap.id, titolo = cap.titolo, serve = cap.serve, aspetta = cap.aspetta or false,
		livelli = cap.missioni }
end

io.write(json({
	capitoli = capitoli,
	catalogo = {
		armi = armi, eventi = insieme(eventi), disegni = insieme(disegni), facce = insieme(facce), mappe = mappe,
		pose = insieme(clip),
		gesti = it.match.gestures.telefono,
		mondo = { w = 1920, h = 1080 },
	},
}), "\n")
