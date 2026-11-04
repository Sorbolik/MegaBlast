-- End-of-match podium: the steps rise, on top of each step the player's Scoria
-- in their team color, on the step place, name and match points (computed by
-- the sim, g:results()). Below, the awards (sim/awards.lua) and what was
-- gained: experience and level.
--
-- Use (from the gui_script):
--   local p = podio.new(results, giocatori, me, gain, prof, numero)
--     results: the sim's g:results(); giocatori[robot] = { nome, colore, vetrina }
--     me: the robot of whoever plays on this phone online (nil locally)
--     gain: profilo.match_end(...) of whoever plays on this phone, or nil; prof: the profile
--     numero: the match in the profile, if it has the replay (there is RIVEDI)
--   podio.update(p, dt) ; podio.on_input(p, action_id, action) -> "continua", { rivedi = numero } or nil
--   tapping a player on the podium opens their tag (ui/tag_card.lua); a tap closes it
--   podio.destroy(p)

local ui = require "ui.ui"
local scoria = require "battle.scoria"
local game = require "sim.game"
local awards = require "sim.awards"
local profile = require "menu.profile"
local tag = require "ui.tag_card"
local T = require("lang.text").podium
local common = require("lang.text").common

local M = {}

-- steps from left to right, by standings position: 2nd, 1st, 3rd, 4th
-- (in 2 vs 2 teammates share the place: the winning pair is in the middle)
M.ORDINE = { 2, 1, 3, 4 }
M.HEIGHT = { 170, 125, 95, 70 }   -- height of each place
M.WIDE, M.STEP = 190, 205        -- step width and distance between centers
M.BASE_Y_POS = 250                     -- where the steps rest
M.SCORIA_H = 110                   -- the Scoria on the step, in pixels
-- entrance timing: the steps rise one after the other, then the awards
M.RISE, M.DELAY, M.REWARDS = 0.45, 0.18, 1.0

local MODES_LIST = T.modes

local function vec(x, y) return vmath.vector3(x, y, 0) end

-- solid outline in the player's color
local function thread(x, y, w, h, color, parent)
	local n = gui.new_box_node(vec(x, y), vec(w, h))
	gui.set_color(n, color)
	gui.set_parent(n, parent)
	return n
end

local function stair(p, x, voice, i)
	local c = ui.C
	local g = p.giocatori[voice.robot] or { nome = "?", colore = c.TEXT }
	local h = M.HEIGHT[voice.place] or M.HEIGHT[#M.HEIGHT]
	-- the step grows from the bottom: it sits in an empty node at the base, which stretches
	local base = gui.new_box_node(vec(x, M.BASE_Y_POS), vec(0, 0))
	gui.set_visible(base, false)
	gui.set_parent(base, p.radice)
	local block = ui.pannello(0, h / 2, M.WIDE, h, base)
	local top = h / 2
	thread(0, top, M.WIDE, 4, g.colore, block)
	ui.titolo(tostring(voice.place), 0, top - 42, 1.3, voice.place == 1 and c.BRACE or c.TEXT, block)
	ui.testo(g.nome, 0, top - 82, 1, g.colore, block)
	ui.testo(T.points:format(voice.points or 0), 0, top - 106, 0.8, c.OFF, block)
	gui.set_scale(base, vmath.vector3(1, 0.01, 1))
	local delay = (i - 1) * M.DELAY
	gui.animate(base, "scale.y", 1, gui.EASING_OUTBACK, M.RISE, delay)

	-- the Scoria drops onto the step once it has risen
	local pose = gui.new_box_node(vec(x, M.BASE_Y_POS + h + 260), vec(0, 0))
	gui.set_visible(pose, false)
	gui.set_parent(pose, p.radice)
	local k = M.SCORIA_H / game.DISEGNO_H
	gui.set_scale(pose, vmath.vector3(k, k, 1))
	gui.animate(pose, "position.y", M.BASE_Y_POS + h, gui.EASING_INQUAD, 0.3, delay + M.RISE * 0.7)
	local s = scoria.new(g.colore, scoria.PERSONAGGIO)
	gui.set_parent(s.root, pose)
	scoria.set_enabled(s, true)
	-- tapping step or devil, their tag
	if g.vetrina then
		local zone = gui.new_box_node(vec(x, M.BASE_Y_POS + (h + M.SCORIA_H + 30) / 2), vec(M.WIDE, h + M.SCORIA_H + 30))
		gui.set_visible(zone, false)
		gui.set_parent(zone, p.radice)
		p.buttons[#p.buttons + 1] = { nodo = zone, bordo = zone, ui_action = "carta:" .. voice.robot, colore = c.LIGHT, riposo = c.LIGHT }
	end
	p.figure[#p.figure + 1] = { s = s, posa = pose,
		st = { x = 0, y = 0, facing = x < 640 and 1 or -1, grounded = true, moving = 0, turno = true,
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
		color = won and c.BRACE or c.TEXT
	elseif results.winner then
		-- in 2 vs 2 the team wins: the name without the teammate's number
		label = T.wins:format(string.upper(results.mode == "2v2" and g.nome:gsub(" %d$", "") or g.nome))
		color = g.colore
	end
	ui.titolo(label, 640, 660, 1.4, color, p.radice)
	ui.testo(MODES_LIST[results.mode] or "", 640, 618, 0.8, c.OFF, p.radice)
end

-- an award's card: name, who got it, why
local function prize(p, x, y, voice, i)
	local c = ui.C
	local g = p.giocatori[voice.robot] or { nome = "?", colore = c.TEXT }
	local n = ui.pannello(x, y, 250, 92, p.radice)
	thread(-121, 0, 4, 80, g.colore, n)
	ui.titolo(voice.award.name, 0, 24, 0.6, c.BRACE, n)
	ui.testo(g.nome, 0, -2, 0.9, g.colore, n)
	ui.testo(voice.award.desc, 0, -26, 0.75, c.OFF, n)
	gui.set_scale(n, vmath.vector3(0.01, 0.01, 1))
	gui.animate(n, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.3, M.REWARDS + i * 0.12)
end

-- experience and level gained by whoever plays on this phone
local function gain(p, g, prof)
	local c = ui.C
	local n = ui.pannello(1065, 105, 330, 120, p.radice)
	ui.testo(T.level:format(g.livello), -80, 34, 1, g.livello > g.level_before and c.BRACE or c.TEXT, n)
	ui.testo(T.xp:format(g.xp), 70, 34, 0.8, c.TEXT, n)
	local b = ui.bar(0, 4, 290, 12, c.BRACE, n)
	ui.bar_value(b, 0)
	p.bar, p.bar_end = b, prof.xp / profile.xp_level(prof.livello)
	if g.livello > g.level_before then
		ui.testo(T.skill_point, 0, -32, 0.9, c.BRACE, n)
	end
end

function M.new(results, giocatori, me, my_gain, prof, number)
	local p = { giocatori = giocatori, me = me, figure = {}, buttons = {}, t = 0, numero = number }
	-- background stretched over the whole screen, the rest in a group that adapts (FIT)
	p.fondo = ui.sfondo()
	p.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(p.radice, false)
	local ranking = results.ranking
	title(p, results, ranking[1])

	-- steps in the order 2nd, 1st, 3rd, 4th, centered by how many there are
	local lane = {}
	for _, k in ipairs(M.ORDINE) do
		if ranking[k] then lane[#lane + 1] = ranking[k] end
	end
	local x0 = 640 - (#lane - 1) * M.STEP / 2
	for i, v in ipairs(lane) do
		-- they rise by place: the 4th first, the 1st last
		stair(p, x0 + (i - 1) * M.STEP, v, #ranking - v.place + 1)
	end

	-- awards at the bottom left
	local _, list_of = awards.assign(ranking)
	for i, voice in ipairs(list_of) do
		if i > 4 then break end
		prize(p, 150 + ((i - 1) % 2) * 260, 155 - math.floor((i - 1) / 2) * 100, voice, i)
	end

	if my_gain then gain(p, my_gain, prof) end
	if number then
		-- RIVEDI: straight to this match's replay (then back to the profile)
		ui.button(p.buttons, 980, 205, 160, 60, common.replay, "rivedi", nil, p.radice)
		ui.button(p.buttons, 1150, 205, 160, 60, T.go_on, "continua", { main = true }, p.radice)
	else
		ui.button(p.buttons, 1065, 205, 330, 60, T.go_on, "continua", { main = true }, p.radice)
	end
	return p
end

function M.update(p, dt)
	p.t = p.t + dt
	for _, s in ipairs(p.figure) do scoria.update(s.s, dt, s.st) end
	if p.carta then tag.update(p.carta, dt) end
	if p.bar and p.t > M.REWARDS then
		ui.bar_value(p.bar, math.min(p.bar_end, (p.t - M.REWARDS) * 0.8))
	end
end

local function close_card(p)
	tag.destroy(p.carta)
	gui.delete_node(p.veil)
	p.carta, p.veil = nil, nil
end

function M.on_input(p, action_id, action)
	-- the tag is open: a tap (or a button) closes it
	if p.carta then
		if action.pressed and (action_id == hash("touch") or action_id == ui.PAD) then close_card(p) end
		return nil
	end
	local ui_action = ui.tocco(p.buttons, action_id, action)
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
	return ui_action
end

function M.destroy(p)
	if p.carta then tag.destroy(p.carta) end
	gui.delete_node(p.radice)
	gui.delete_node(p.fondo)
end

return M
