-- Turni umani: in ogni turno di una persona (le ricette delle partite giocate
-- sul telefono, ramo partite-registrate) rimette la partita a quel momento e fa
-- giocare il turno a un bot al posto suo, poi confronta: quanto ha guadagnato
-- la sua squadra sulle altre in quel turno lei e quanto il bot, con le mosse
-- di tutti e due. Dice dove la persona gioca meglio del bot (quali mosse) e,
-- rifatto con un bot nuovo, se il bot ha imparato.
--
--   luajit tools/arena/turni_umani.lua [--grado 10] [--semi 3] [--pesi pesi.lua]
--          [--uscita simulazione/arena/umani] RICETTA...
--
-- RICETTA: il testo di replay.encode (.lua, dal server) o il JSON di
-- ricevi_partite.py (.json). --pesi: un file che restituisce i pesi del bot
-- (bot.PESI, solo i campi che cambiano) sopra quelli del grado. --semi: quante
-- volte il bot prova ogni turno (con semi diversi: la sua mira ha del rumore).
-- Esce turni.jsonl (una riga per turno) e confronto.md.

package.path = "client/?.lua;" .. package.path

local bot = require "sim.bot"
local replay = require "sim.replay"

local opt = { grado = 10, semi = 3, uscita = "simulazione/arena/umani" }
local files = {}
local i = 1
while arg[i] do
	local k = arg[i]:match("^%-%-(.+)")
	if k then
		assert(arg[i + 1], "manca il valore di --" .. k)
		opt[k] = tonumber(arg[i + 1]) or arg[i + 1]
		i = i + 2
	else
		files[#files + 1] = arg[i]
		i = i + 1
	end
end
assert(#files > 0, "uso: luajit tools/arena/turni_umani.lua [--grado 10] RICETTA...")
local PESI = opt.pesi and dofile(opt.pesi) or nil

-- le mosse, come nella firma dei turni dell'arena (arena.lua)
local USO = {
	fire = "missile", grenade = "grenade", shards = "shards", sniper = "sniper", punch = "punch",
	swing = "sword", eagle = "eagle", mallet = "mallet", lunge = "lunge", bellows = "bellows", hook = "hook",
	orb = "teleport", parachute = "parachute", shield = "shield",
}
-- un turno che non finisce entro questo (90 s) si chiude lì
local MAX_TURNO = 90 * 60

local function leggi(path)
	local f = assert(io.open(path, "rb"))
	local text = f:read("*a")
	f:close()
	if path:match("%.json$") then
		local cjson_ok, cjson = pcall(require, "cjson")
		assert(cjson_ok, "per le ricette .json serve lua-cjson; quelle del server sono .lua")
		return cjson.decode(text)
	end
	return assert(replay.decode(text), "ricetta illeggibile: " .. path)
end

-- quanto la squadra di team è sopra la migliore delle altre
local function margine(g, team)
	local mio, altri = 0, {}
	for _, rb in ipairs(g.robots) do
		if rb.team == team then mio = mio + rb.points else altri[rb.team] = (altri[rb.team] or 0) + rb.points end
	end
	local primo = -math.huge
	for _, v in pairs(altri) do primo = math.max(primo, v) end
	return mio - (primo == -math.huge and 0 or primo)
end

-- Le mosse e le uccisioni di chi dagli eventi; true se è cominciato un altro turno
local function eventi(g, chi, t)
	local altro = false
	for _, e in ipairs(g:pop_events()) do
		local w = USO[e.type] or (e.type == "place" and e.kind) or nil
		if w and e.robot == chi then
			t.mosse[#t.mosse + 1] = w
		elseif e.type == "death" and e.by == chi then
			t.uccisioni = t.uccisioni + 1
		elseif e.type == "turn" then
			altro = true
		end
	end
	return altro
end

local function firma(t)
	return (#t.mosse > 0 and table.concat(t.mosse, ">") or "fermo") .. (t.uccisioni > 0 and "+kill" or "")
end

-- La partita della ricetta portata al tick T, coi tasti della ricetta
local function al_tick(r, T)
	local g, bots = replay.match(r)
	local l = replay.reader(r)
	while g.tick < T and g.phase ~= "over" do
		g:step(replay.read_step(l, g, bots))
		g:pop_events()
	end
	return g
end

-- Prima passata: la partita com'è stata, coi turni delle persone
local function turni_umani(r)
	local umani = {}
	for k, p in ipairs(r.opzioni.players or {}) do
		if not p.bot then umani[k] = true end
	end
	local g, bots = replay.match(r)
	local l = replay.reader(r)
	local out, cur = {}, nil
	local function chiudi()
		if cur then
			cur.fatto = margine(g, g.robots[cur.chi].team) - cur.m0
			cur.vita = g.robots[cur.chi].hp - cur.hp0
			cur.firma = firma(cur)
			out[#out + 1] = cur
			cur = nil
		end
	end
	while g.phase ~= "over" do
		g:step(replay.read_step(l, g, bots))
		for _, e in ipairs(g:pop_events()) do
			local w = USO[e.type] or (e.type == "place" and e.kind) or nil
			if cur and w and e.robot == cur.chi then
				cur.mosse[#cur.mosse + 1] = w
			elseif cur and e.type == "death" and e.by == cur.chi then
				cur.uccisioni = cur.uccisioni + 1
			elseif e.type == "turn" then
				chiudi()
				if umani[e.robot] then
					cur = { t = g.tick, chi = e.robot, m0 = margine(g, g.robots[e.robot].team),
						hp0 = g.robots[e.robot].hp, mosse = {}, uccisioni = 0 }
				end
			end
		end
	end
	chiudi()
	return out, g
end

-- Il bot gioca il turno al posto della persona, dallo stesso momento
local function prova_bot(r, turno, seme)
	local g = al_tick(r, turno.t)
	local rb = g.robots[turno.chi]
	local team = rb.team
	local m0, hp0 = margine(g, team), rb.hp
	local b = bot.new(turno.chi, opt.grado, seme, PESI)
	local t = { mosse = {}, uccisioni = 0 }
	local fine = g.tick + MAX_TURNO
	while g.phase ~= "over" and g.tick < fine do
		g:step(bot.input(b, g))
		if eventi(g, turno.chi, t) then break end
	end
	return margine(g, team) - m0, g.robots[turno.chi].hp - hp0, firma(t)
end

local function json(v)
	local t = type(v)
	if t == "table" then
		local o = {}
		if #v > 0 then
			for _, x in ipairs(v) do o[#o + 1] = json(x) end
			return "[" .. table.concat(o, ",") .. "]"
		end
		local keys = {}
		for k in pairs(v) do keys[#keys + 1] = k end
		table.sort(keys)
		for _, k in ipairs(keys) do o[#o + 1] = string.format("%q:%s", k, json(v[k])) end
		return "{" .. table.concat(o, ",") .. "}"
	elseif t == "string" then
		return string.format("%q", v)
	elseif t == "number" then
		return v == math.floor(v) and string.format("%d", v) or string.format("%.2f", v)
	end
	return tostring(v)
end

os.execute('mkdir -p "' .. opt.uscita .. '"')
local righe = assert(io.open(opt.uscita .. "/turni.jsonl", "w"))
local tutti = {}
for _, path in ipairs(files) do
	local ok, r = pcall(leggi, path)
	if not ok then
		io.stderr:write(path .. ": " .. tostring(r) .. "\n")
	elseif not replay.verify(r) then
		io.stderr:write(path .. ": la ricetta non torna uguale con questo codice, saltata\n")
	else
		local turni = turni_umani(r)
		for _, t in ipairs(turni) do
			local somma, vita, firme = 0, 0, {}
			for s = 1, opt.semi do
				local m, v, f = prova_bot(r, t, s)
				somma, vita = somma + m, vita + v
				firme[#firme + 1] = f
			end
			local riga = { partita = path:match("[^/\\]+$"), tick = t.t, chi = t.chi, mappa = r.mappa,
				persona = t.fatto, persona_vita = t.vita, persona_firma = t.firma,
				bot = somma / opt.semi, bot_vita = vita / opt.semi, bot_firme = firme }
			righe:write(json(riga), "\n")
			tutti[#tutti + 1] = riga
		end
		io.stderr:write(string.format("%s: %d turni\n", path, #turni))
	end
end
righe:close()

-- Il confronto: in totale e per firma delle mosse della persona
local n, tot_p, tot_b, meglio, peggio = #tutti, 0, 0, 0, 0
local per = {}
for _, x in ipairs(tutti) do
	tot_p, tot_b = tot_p + x.persona, tot_b + x.bot
	if x.persona > x.bot + 0.5 then meglio = meglio + 1 elseif x.persona < x.bot - 0.5 then peggio = peggio + 1 end
	local f = x.persona_firma
	local p = per[f] or { firma = f, n = 0, persona = 0, bot = 0 }
	per[f] = p
	p.n, p.persona, p.bot = p.n + 1, p.persona + x.persona, p.bot + x.bot
end
local lista = {}
for _, p in pairs(per) do lista[#lista + 1] = p end
table.sort(lista, function(a, b)
	local da, db = a.persona - a.bot, b.persona - b.bot
	if da ~= db then return da > db end
	return a.firma < b.firma
end)
local md = assert(io.open(opt.uscita .. "/confronto.md", "w"))
md:write(string.format("# Turni umani contro il grado %s\n\n", tostring(opt.grado)))
md:write(string.format("%d partite, %d turni della persona, il bot prova ogni turno %d volte.\n\n", #files, n, opt.semi))
if n > 0 then
	md:write(string.format("- Punti di vantaggio a turno: persona %.1f, bot %.1f\n", tot_p / n, tot_b / n))
	md:write(string.format("- Turni in cui la persona fa meglio: %d (%.0f%%), peggio: %d (%.0f%%)\n\n",
		meglio, 100 * meglio / n, peggio, 100 * peggio / n))
	md:write("## Per mosse della persona (dove fa più del bot in alto)\n\n| mosse | turni | persona | bot | differenza |\n|---|---|---|---|---|\n")
	for _, p in ipairs(lista) do
		md:write(string.format("| %s | %d | %.1f | %.1f | %+.1f |\n", p.firma, p.n, p.persona / p.n, p.bot / p.n, (p.persona - p.bot) / p.n))
	end
end
md:close()
print(string.format("%d turni: persona %.1f, bot %.1f punti a turno; %s/confronto.md", n,
	n > 0 and tot_p / n or 0, n > 0 and tot_b / n or 0, opt.uscita))
