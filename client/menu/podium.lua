-- End-of-match podium (redone 10 Nov, Sergio: "del podio di oggi puoi rifare
-- tutto"; drawn with ui/kit.lua, Figma coordinates). On the left the result on
-- a light plate and the steps, one per team (in free-for-all one per player):
-- on each the devils of that team with their names, the points and the awards
-- they took (sim/awards.lua); the MVP has a gold tag over the head. On the
-- right the receipt of whoever plays on this phone (ui/receipt.lua): every line
-- of the experience and the coins, the totals, the level and, with a new
-- level, METTI I PUNTI that takes you to the Sigilli.
--
-- Use (from the gui_script):
--   local p = podio.new(results, giocatori, me, gain, prof, numero)
--     results: the sim's g:results(); giocatori[robot] = { nome, colore, vetrina }
--     me: the robot of whoever plays on this phone online (nil locally)
--     gain: profile.match_end(...) of whoever plays on this phone, or nil; prof: the profile
--     numero: the match in the profile, if it has the replay (there is RIVEDI)
--   p.tick = function(i) ... end   -- optional: the sound of the receipt's i-th line
--   p.coin = function(kind, i) ... end  -- optional: a coin landing in the wallet pill
--   p.xp = function(i, n, level_up) ... end  -- optional: a spark of experience landing in the bar
--   podio.update(p, dt) ; podio.on_input(p, action_id, action) -> "continua", "sigilli", { rivedi = numero } or nil
--   tapping a player on the podium opens their tag (ui/tag_card.lua); a tap closes it
--   podio.destroy(p)

local ui = require "ui.ui"
local kit = require "ui.kit"
local backdrop = require "ui.backdrop"
local scoria = require "battle.scoria"
local game = require "sim.game"
local awards = require "sim.awards"
local tag = require "ui.tag_card"
local receipt = require "ui.receipt"
local T = require("lang.text").podium
local common = require("lang.text").common

local M = {}

local KC = kit.C
-- how tall a step is by place (two steps: the second lower), where they rest
M.HEIGHT = { 221, 171, 131, 101 }
M.HEIGHT_TWO = { 221, 141 }
M.FLOOR = 661
-- entrance timing: the steps rise one after the other, then the awards
M.RISE, M.DELAY, M.REWARDS = 0.45, 0.18, 1.0
local CHIP_COLORS = { KC.HOT, KC.PURPLE, KC.STEEL, KC.MINT }

local MODES_LIST = T.modes

local function vec(x, y) return vmath.vector3(x, y, 0) end

-- an empty node at (x, y) of the kit, with its group: what is drawn in it
-- scales and pops around that point
local function holder(p, x, y)
	local n = gui.new_box_node(vec(x, 720 - y), vec(0, 0))
	gui.set_visible(n, false)
	gui.set_parent(n, p.radice)
	return { node = n, ox = x, oy = y }
end

local function pop(n, delay)
	gui.set_scale(n, vec(0.01, 0.01))
	gui.animate(n, "scale", vec(1, 1), gui.EASING_OUTBACK, 0.3, delay)
end

-- A step: block = { members (ranking rows), points, place }; x, w, h in the kit
local function stair(p, block, i, count, x, w, h, per_robot, mvp, team_mode)
	local y = M.FLOOR - h
	local first_one = p.giocatori[block.members[1].robot] or { nome = "?", colore = KC.SAND }
	local color = first_one.colore
	local delay = (count - i) * M.DELAY
	-- the step grows from the floor
	local base = holder(p, x + w / 2, M.FLOOR)
	kit.plate(base, x, y, w, h, color, { sk = 0, d = 10 })
	local size = h >= 200 and 84 or h >= 140 and 54 or 40
	local line = h >= 200 and y + 100 or h >= 140 and y + 60 or y + 48
	kit.text(base, tostring(block.points), x + w / 2, line, size, KC.SAND, "middle")
	local name = team_mode and first_one.nome:gsub(" %d$", "") or first_one.nome
	local under = kit.text(base, kit.upper(name), x + w / 2, line + (h >= 200 and 34 or h >= 140 and 24 or 20),
		h >= 200 and 16 or 13, color, "middle", 2)
	local wide = kit.width(under)
	if wide > w - 24 then
		local sc = gui.get_scale(under)
		gui.set_scale(under, vec(sc.x * (w - 24) / wide, sc.y * (w - 24) / wide))
	end
	gui.set_scale(base.node, vmath.vector3(1, 0.01, 1))
	gui.animate(base.node, "scale.y", 1, gui.EASING_OUTBACK, M.RISE, delay)

	-- the devils drop onto the step once it has risen
	local n = #block.members
	local tall = (i == 1 and 143 or 126) * (w < 200 and 0.85 or 1)
	local chips = {}
	for k, voice in ipairs(block.members) do
		local g = p.giocatori[voice.robot] or { nome = "?", colore = KC.SAND }
		local cx = x + w * (2 * k - 1) / (2 * n) - (n > 1 and 6 or 0)
		local land = 720 - y - 4
		local pose = gui.new_box_node(vec(cx, land + 260), vec(0, 0))
		gui.set_visible(pose, false)
		gui.set_parent(pose, p.radice)
		local sc = tall / game.DISEGNO_H
		gui.set_scale(pose, vmath.vector3(sc, sc, 1))
		gui.animate(pose, "position.y", land, gui.EASING_INQUAD, 0.3, delay + M.RISE * 0.7)
		local s = scoria.new(g.colore, scoria.PERSONAGGIO)
		gui.set_parent(s.root, pose)
		scoria.set_enabled(s, true)
		p.figure[#p.figure + 1] = { s = s, posa = pose,
			st = { x = 0, y = 0, facing = 1, grounded = true, moving = 0, turno = true, vittoria = block.place == 1 } }
		-- over the head the name (a team's step has its name on it) and the MVP's tag
		local head = y - tall * 1.32
		local is_mvp = voice.robot == mvp
		if team_mode or is_mvp then
			local over = holder(p, cx, head - 14)
			if is_mvp then
				kit.para(over, cx - 46, head - 18, 84, 26, 8, KC.HOT)
				kit.text(over, T.mvp, cx, head + 1, 15, KC.INK, "middle", 1.5)
			end
			if team_mode then kit.text(over, kit.upper(g.nome), cx, head - (is_mvp and 26 or 8), 13, KC.SAND, "middle", 1) end
			pop(over.node, M.REWARDS)
		end
		for _, aw in ipairs(per_robot[voice.robot] or {}) do chips[#chips + 1] = aw.name end
		-- tapping the devil, their tag
		if g.vetrina then kit.zone({ node = p.radice, ox = 0, oy = 720 }, p.buttons, cx - 56, head, 112, tall * 1.32 + 30, "carta:" .. voice.robot) end
	end

	-- the awards on the step, as many as fit
	local cx, cy = x + 20, line + (h >= 200 and 60 or 40)
	for j, t in ipairs(chips) do
		local wide_chip = #t * 9 + 34
		if cx + wide_chip > x + w and cx > x + 20 then cx, cy = x + 20, cy + 28 end
		if cy + 24 > M.FLOOR - 4 then break end
		local c = holder(p, cx + wide_chip / 2, cy + 11)
		kit.label(c, cx, cy, t, CHIP_COLORS[(j - 1) % #CHIP_COLORS + 1], true)
		pop(c.node, M.REWARDS + 0.1 * j)
		cx = cx + wide_chip
	end
end

-- results.winner: the winning team, nil on a tie
local function title(p, results, first)
	local g = p.giocatori[first.robot] or { nome = "?" }
	local label = T.tie
	if results.winner and p.me then
		local my_team
		for _, v in ipairs(results.ranking) do
			if v.robot == p.me then my_team = v.team end
		end
		label = results.winner == my_team and T.victory or T.defeat
	elseif results.winner then
		-- in 2 vs 2 the team wins: the name without the teammate's number
		label = T.wins:format(kit.upper(results.mode == "2v2" and g.nome:gsub(" %d$", "") or g.nome))
	end
	local gg = { node = p.radice, ox = 0, oy = 720 }
	kit.sand(gg, 30, 36, 420, 104, KC.HOT, { sk = 34, d = 14 })
	local t = kit.text(gg, label, 64, 116, 74, KC.INK)
	local wide = kit.width(t)
	if wide > 372 then
		local sc = gui.get_scale(t)
		gui.set_scale(t, vec(sc.x * 372 / wide, sc.y * 372 / wide))
	end
	kit.info(gg, 70, 156, 300, 36, KC.HOT)
	kit.text(gg, MODES_LIST[results.mode] or "", 220, 181, 16, KC.SAND, "middle", 1)
end

function M.new(results, giocatori, me, my_gain, prof, number)
	local p = { giocatori = giocatori, me = me, figure = {}, buttons = {}, t = 0, numero = number }
	-- a dark sheet and the rays, the rest in a group that adapts (FIT)
	p.fondo = backdrop.new()
	p.scene = kit.scene(330, 330, {})
	p.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(p.radice, false)
	local ranking = results.ranking
	title(p, results, ranking[1])

	-- one step per team, in the order of the standings
	local blocks = {}
	for _, v in ipairs(ranking) do
		local last = blocks[#blocks]
		if last and last.team == v.team then
			last.members[#last.members + 1] = v
			last.points = last.points + (v.points or 0)
		else
			blocks[#blocks + 1] = { team = v.team, place = v.place, points = v.points or 0, members = { v } }
		end
	end
	local per_robot = awards.assign(ranking)
	local mvp = awards.mvp(ranking)
	local count = #blocks
	local team_mode = #ranking > count
	local heights = count <= 2 and M.HEIGHT_TWO or M.HEIGHT
	local x = count <= 2 and 110 or 60
	for i, b in ipairs(blocks) do
		local w = count <= 2 and (i == 1 and 300 or 270) or count == 3 and 200 or 156
		stair(p, b, i, count, x, w, heights[b.place] or heights[#heights], per_robot, mvp, team_mode)
		x = x + w + (count <= 2 and 30 or 14)
	end

	-- on the right the receipt, under it the buttons
	if my_gain then
		p.receipt = receipt.new(my_gain, prof, 130, p.buttons, p.radice)
	end
	p.right = kit.anchor(1280, 720, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	if number then
		-- RIVEDI: straight to this match's replay (then back to the profile)
		local again = kit.plate(p.right, 740, 584, 160, 56, KC.ROSE, { sk = 14, d = 6 })
		kit.text(again.g, common.replay, 740 + 87, 584 + 36, 18, KC.SAND, "middle", 0.5)
		kit.button(p.buttons, again, "rivedi")
	end
	local go = kit.action(p.right, T.go_on, 930, 560, 270, 84, { size = 44 })
	kit.button(p.buttons, go, "continua", { main = true })
	return p
end

function M.update(p, dt)
	p.t = p.t + dt
	for _, s in ipairs(p.figure) do scoria.update(s.s, dt, s.st) end
	if p.carta then tag.update(p.carta, dt) end
	if p.receipt then receipt.update(p.receipt, dt, p.tick, p.coin, p.xp) end
end

local function close_card(p)
	tag.destroy(p.carta)
	gui.delete_node(p.veil)
	p.carta, p.veil = nil, nil
end

function M.on_input(p, action_id, action)
	-- the tag is open: a tap (or a button) closes it
	if p.carta then
		if action.pressed and (action_id == ui.TOUCH or action_id == ui.PAD) then close_card(p) end
		return nil
	end
	local ui_action = ui.touch(p.buttons, action_id, action)
	if ui_action == "rivedi" then return { rivedi = p.numero } end
	local robot = ui_action and tonumber(ui_action:match("^carta:(%d+)$"))
	if robot then
		local v = p.giocatori[robot].vetrina
		p.veil = gui.new_box_node(vec(640, 360), vec(1280 * 4, 720 * 4))
		gui.set_color(p.veil, vmath.vector4(ui.C.BOTTOM.x, ui.C.BOTTOM.y, ui.C.BOTTOM.z, 0.82))
		gui.set_parent(p.veil, p.radice)
		v.verso = 1
		p.carta = tag.new(v, 640, 360 + tag.TALL({ portrait = true }) / 2, { portrait = true, tu = v.tu }, p.radice)
		return nil
	end
	-- a tap anywhere else while the receipt counts: everything at once
	if not ui_action and p.receipt and action.pressed and action_id == ui.TOUCH then receipt.skip(p.receipt) end
	return ui_action
end

function M.destroy(p)
	if p.carta then tag.destroy(p.carta) end
	if p.receipt then receipt.delete(p.receipt) end
	gui.delete_node(p.radice)
	gui.delete_node(p.right.node)
	for _, n in ipairs(p.scene.tops) do gui.delete_node(n) end
	gui.delete_node(p.fondo)
end

return M
