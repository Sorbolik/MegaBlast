-- Online in lockstep (sim/netkeys.lua): the keys of a tick travel as a short
-- text, and a phone that steps its copy of the match with the codes the
-- server sends gets exactly the server's match. From the root:
--   luajit tests/netkeys_test.lua
package.path = "client/?.lua;" .. package.path

local game = require "sim.game"
local bot = require "sim.bot"
local netkeys = require "sim.netkeys"

local failures = 0
local function check(cond, msg)
	if cond then
		print("ok   " .. msg)
	else
		print("FAIL " .. msg)
		failures = failures + 1
	end
end

-- the codes come back as the same input, and a decoded input encodes the same
local inputs = {
	{},
	{ left = true, hold = false },
	{ right = true, jump = true, hold = true },
	{ fire = { weapon = "teleport", angle = math.pi / 3, power = 0.123456789 } },
	{ left = true, jump = true, hold = false, fire = { weapon = "missile", angle = -1e-7, power = 1 } },
}
for i, input in ipairs(inputs) do
	local code = netkeys.encode(input)
	local back = netkeys.decode(code)
	local again = netkeys.encode(back)
	check(again == code, "codice " .. i .. " stabile: " .. code)
	if input.fire then
		check(back.fire.angle == input.fire.angle and back.fire.power == input.fire.power,
			"codice " .. i .. ": angolo e forza esatti")
	end
end
check(netkeys.encode(nil) == "" and netkeys.decode("") == nil, "nessun tasto: codice vuoto")
check(netkeys.decode("zz") == nil and netkeys.decode("f,1") == nil, "un codice sbagliato non vale")
check(netkeys.decode("fbanana,1,1").fire.weapon == "missile", "un'arma che non c'è diventa il lanciarune")
local input, gone = netkeys.decode("x2;x3;r")
check(input and input.right and gone and gone[1] == 2 and gone[2] == 3, "chi esce prima del tick (x2;x3;)")
check(netkeys.encode({ fire = { weapon = "nonesiste", angle = 1, power = 1 } }):sub(1, 8) == "fmissile",
	"anche mandandola")

-- Four bots play a 2v2 on the "server"; the "phone" steps its copy only with
-- the codes: the fingerprints are always the same
local players = { { team = 1 }, { team = 2 }, { team = 1 }, { team = 2 } }
local function new() return game.new(77, nil, { players = players, random_spawns = true, intro = game.INTRO_TICKS }) end
local server, phone = new(), new()
local bots = {}
for i = 1, 4 do bots[i] = bot.new(i, 6, 77) end
local same, shots = true, 0
for _ = 1, 60 * 60 * 3 do
	if server.phase == "over" then break end
	local code, clean = netkeys.clean(bot.input(bots[server.current], server))
	if clean and clean.fire then shots = shots + 1 end
	server:step(clean)
	phone:step((netkeys.decode(code)))
	if server.tick % 30 == 0 and server:fingerprint() ~= phone:fingerprint() then
		same = false
		break
	end
end
check(shots > 3, "i bot hanno sparato (" .. shots .. " colpi)")
check(same and server:fingerprint() == phone:fingerprint(), "il telefono coi soli codici ha la stessa partita del server (tick " .. server.tick .. ")")

-- The copy of the match a bot tries its moves on (bot.world) never writes into
-- the real one: on the server the bots think, on the phones they don't, and a
-- shared table (a pool's lit, who a swing or the cannon hit) made the server's
-- match split from the phones' (Sergio, 23 Nov: the loop of reconnections)
do
	local g = new()
	local rb = g.robots[2]
	rb.melee_hit, rb.cannon = { [1] = true }, { wait = 3, hit = { [3] = true } }
	g.pools[1] = { id = 1, x = 10, y = 10, r = 60, turns = 3, owner = 1, team = 1, lit = { [2] = 1 } }
	g.projectile = { x = 1, y = 2, hit = { [4] = true } }
	g.flying[1] = { x = 3, y = 4, hit = { [2] = true } }
	local function dump(t, seen)
		seen = seen or {}
		if type(t) ~= "table" then return tostring(t) end
		if seen[t] then return "@" end
		seen[t] = true
		local keys = {}
		for k in pairs(t) do keys[#keys + 1] = k end
		table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
		local out = {}
		for _, k in ipairs(keys) do
			if k ~= "terrain" and k ~= "stats" and type(t[k]) ~= "function" then out[#out + 1] = tostring(k) .. "=" .. dump(t[k], seen) end
		end
		return "{" .. table.concat(out, ",") .. "}"
	end
	local before = dump({ g.robots, g.pools, g.projectile, g.flying, g.orbs, g.placed })
	local w = bot.world(g)
	-- every table of the copy written over
	local function scribble(t, depth)
		if depth > 4 then return end
		for k, v in pairs(t) do
			if type(v) == "table" and k ~= "stats" then
				scribble(v, depth + 1)
				v.scritto = true
			end
		end
	end
	scribble({ w.robots, w.pools, w.projectile, w.flying, w.orbs, w.placed }, 0)
	check(dump({ g.robots, g.pools, g.projectile, g.flying, g.orbs, g.placed }) == before, "la copia del bot non scrive nella partita vera")
end

if failures > 0 then
	print(failures .. " controlli falliti")
	os.exit(1)
end
print("tutti i controlli ok")
