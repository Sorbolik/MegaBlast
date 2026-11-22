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

if failures > 0 then
	print(failures .. " controlli falliti")
	os.exit(1)
end
print("tutti i controlli ok")
