-- End-of-match podium (redone 10 Nov, Sergio: "del podio di oggi puoi rifare
-- tutto"). On the left the result and the steps: on each one the player's
-- Scoria in their team color, place, name, match points (the sim's
-- g:results()) and under it the awards they took (sim/awards.lua); the MVP has
-- a gold tag over the head. On the right the receipt of whoever plays on this
-- phone (ui/receipt.lua): every line of the experience, the total, the level
-- and, with a new level, METTI I PUNTI that takes you to the Sigilli.
--
-- Use (from the gui_script):
--   local p = podio.new(results, giocatori, me, gain, prof, numero)
--     results: the sim's g:results(); giocatori[robot] = { nome, colore, vetrina }
--     me: the robot of whoever plays on this phone online (nil locally)
--     gain: profile.match_end(...) of whoever plays on this phone, or nil; prof: the profile
--     numero: the match in the profile, if it has the replay (there is RIVEDI)
--   p.tick = function(i) ... end   -- optional: the sound of the receipt's i-th line
--   podio.update(p, dt) ; podio.on_input(p, action_id, action) -> "continua", "sigilli", { rivedi = numero } or nil
--   tapping a player on the podium opens their tag (ui/tag_card.lua); a tap closes it
--   podio.destroy(p)

local ui = require "ui.ui"
local backdrop = require "ui.backdrop"
local scoria = require "battle.scoria"
local game = require "sim.game"
local awards = require "sim.awards"
local tag = require "ui.tag_card"
local receipt = require "ui.receipt"
local T = require("lang.text").podium
local common = require("lang.text").common

local M = {}

-- steps from left to right, by standings position: 2nd, 1st, 3rd, 4th
-- (in 2 vs 2 teammates share the place: the winning pair is in the middle)
M.ORDINE = { 2, 1, 3, 4 }
M.HEIGHT = { 150, 112, 88, 68 }   -- height of each place
M.WIDE, M.STEP = 152, 164         -- step width and distance between centers
M.CENTER_X = 420                  -- the middle of the podium (the receipt is on the right)
M.BASE_Y_POS = 120                -- where the steps rest (under them the awards)
M.SCORIA_H = 104                  -- the Scoria on the step, in pixels
M.RECEIPT_X, M.RECEIPT_TOP = 1040, 676
-- entrance timing: the steps rise one after the other, then the awards
M.RISE, M.DELAY, M.REWARDS = 0.45, 0.18, 1.0

local MODES_LIST = T.modes

local function vec(x, y) return vmath.vector3(x, y, 0) end

local function stair(p, x, voice, i, prizes, mvp)
	local c = ui.C
	local g = p.giocatori[voice.robot] or { nome = "?", colore = c.TEXT }
	local h = M.HEIGHT[voice.place] or M.HEIGHT[#M.HEIGHT]
	-- the step grows from the bottom: it sits in an empty node at the base, which stretches
	local base = gui.new_box_node(vec(x, M.BASE_Y_POS), vec(0, 0))
	gui.set_visible(base, false)
	gui.set_parent(base, p.radice)
	-- the step's border in the team color, like the tags in the lineup
	local block, edge = ui.panel(0, h / 2, M.WIDE, h, base)
	gui.set_color(edge, g.colore)
	local top = h / 2
	ui.title(tostring(voice.place), 0, top - 30, 0.9, voice.place == 1 and c.GOLD or c.TEXT, block)
	ui.text(g.nome, 0, top - 60, 0.85, g.colore, block)
	ui.text(T.points:format(voice.points or 0), 0, top - 82, 0.7, c.OFF, block)
	gui.set_scale(base, vmath.vector3(1, 0.01, 1))
	local delay = (i - 1) * M.DELAY
	gui.animate(base, "scale.y", 1, gui.EASING_OUTBACK, M.RISE, delay)

	-- the Scoria drops onto the step once it has risen
	local land = M.BASE_Y_POS + h
	local pose = gui.new_box_node(vec(x, land + 260), vec(0, 0))
	gui.set_visible(pose, false)
	gui.set_parent(pose, p.radice)
	local k = M.SCORIA_H / game.DISEGNO_H
	gui.set_scale(pose, vmath.vector3(k, k, 1))
	gui.animate(pose, "position.y", land, gui.EASING_INQUAD, 0.3, delay + M.RISE * 0.7)
	local s = scoria.new(g.colore, scoria.PERSONAGGIO)
	gui.set_parent(s.root, pose)
	scoria.set_enabled(s, true)
	-- the MVP's tag over the head, once everyone is up
	if mvp then
		local n = gui.new_box_node(vec(x, land + M.SCORIA_H + 34), vec(84, 30))
		gui.set_color(n, c.GOLD)
		gui.set_parent(n, p.radice)
		ui.title(T.mvp, 0, 0, 0.5, c.BOTTOM, n)
		gui.set_scale(n, vec(0.01, 0.01))
		gui.animate(n, "scale", vec(1, 1), gui.EASING_OUTBACK, 0.3, M.REWARDS)
	end
	-- the awards under the step
	for j, aw in ipairs(prizes or {}) do
		-- in an empty node: the pop animates that, not the text's own scale
		local n = gui.new_box_node(vec(x, M.BASE_Y_POS - 22 - (j - 1) * 26), vec(0, 0))
		gui.set_visible(n, false)
		gui.set_parent(n, p.radice)
		ui.text(aw.name, 0, 0, 0.7, c.GOLD, n)
		gui.set_scale(n, vec(0.01, 0.01))
		gui.animate(n, "scale", vec(1, 1), gui.EASING_OUTBACK, 0.3, M.REWARDS + 0.1 * j)
	end
	-- tapping step or devil, their tag
	if g.vetrina then
		local zone = gui.new_box_node(vec(x, M.BASE_Y_POS + (h + M.SCORIA_H + 30) / 2), vec(M.WIDE, h + M.SCORIA_H + 30))
		gui.set_visible(zone, false)
		gui.set_parent(zone, p.radice)
		p.buttons[#p.buttons + 1] = { nodo = zone, bordo = zone, ui_action = "carta:" .. voice.robot, colore = c.LIGHT, riposo = c.LIGHT }
	end
	p.figure[#p.figure + 1] = { s = s, posa = pose,
		st = { x = 0, y = 0, facing = x < M.CENTER_X and 1 or -1, grounded = true, moving = 0, turno = true,
			vittoria = voice.place == 1 } }
end

-- results.winner: the winning team, nil on a tie
local function title(p, results, first)
	local c = ui.C
	local g = p.giocatori[first.robot] or { nome = "?", colore = c.TEXT }
	local label, color = T.tie, c.TEXT
	if results.winner and p.me then
		local my_team
		for _, v in ipairs(results.ranking) do
			if v.robot == p.me then my_team = v.team end
		end
		local won = results.winner == my_team
		label = won and T.victory or T.defeat
		color = won and c.GOLD or c.TEXT
	elseif results.winner then
		-- in 2 vs 2 the team wins: the name without the teammate's number
		label = T.wins:format(string.upper(results.mode == "2v2" and g.nome:gsub(" %d$", "") or g.nome))
		color = g.colore
	end
	ui.title(label, M.CENTER_X, 650, 1.3, color, p.radice)
	ui.text(MODES_LIST[results.mode] or "", M.CENTER_X, 606, 0.8, c.OFF, p.radice)
end

function M.new(results, giocatori, me, my_gain, prof, number)
	local p = { giocatori = giocatori, me = me, figure = {}, buttons = {}, t = 0, numero = number }
	-- background stretched over the whole screen, the rest in a group that adapts (FIT)
	p.fondo = backdrop.new("raggi")
	p.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(p.radice, false)
	local ranking = results.ranking
	title(p, results, ranking[1])

	-- steps in the order 2nd, 1st, 3rd, 4th, centered by how many there are
	local lane = {}
	for _, k in ipairs(M.ORDINE) do
		if ranking[k] then lane[#lane + 1] = ranking[k] end
	end
	local per_robot = awards.assign(ranking)
	local mvp = awards.mvp(ranking)
	local x0 = M.CENTER_X - (#lane - 1) * M.STEP / 2
	for i, v in ipairs(lane) do
		-- they rise by place: the 4th first, the 1st last
		stair(p, x0 + (i - 1) * M.STEP, v, #ranking - v.place + 1, per_robot[v.robot], v.robot == mvp)
	end

	-- on the right the receipt, under it the buttons
	if my_gain then
		p.receipt = receipt.new(my_gain, prof, M.RECEIPT_X, M.RECEIPT_TOP, p.buttons, p.radice)
	end
	local half = receipt.W / 2
	if number then
		-- RIVEDI: straight to this match's replay (then back to the profile)
		ui.button(p.buttons, M.RECEIPT_X - half + 80, 52, 160, 60, common.replay, "rivedi", nil, p.radice)
		ui.button(p.buttons, M.RECEIPT_X + 90, 52, half * 2 - 180, 60, T.go_on, "continua", { main = true }, p.radice)
	else
		ui.button(p.buttons, M.RECEIPT_X, 52, half * 2, 60, T.go_on, "continua", { main = true }, p.radice)
	end
	return p
end

function M.update(p, dt)
	p.t = p.t + dt
	for _, s in ipairs(p.figure) do scoria.update(s.s, dt, s.st) end
	if p.carta then tag.update(p.carta, dt) end
	if p.receipt then receipt.update(p.receipt, dt, p.tick) end
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
	gui.delete_node(p.radice)
	gui.delete_node(p.fondo)
end

return M
