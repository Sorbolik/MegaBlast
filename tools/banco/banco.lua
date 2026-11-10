-- Weapon test bench (no bots): each weapon, alone, against a still target in the sky.
-- From the repository root:  luajit tools/banco/banco.lua [arma ...] [--md file]
-- Sweeps distance, angle and power, fires once and measures what the simulation does:
-- damage to the target (hp lost, no statuses counted), how far it gets knocked, the
-- reach (largest distance with a hit), the best shot and how many of those kill from 100.
-- The target has 1000 hp (damage is what it loses until the shot is over) and stands on the floor.
-- Weapons are found in game.CRATE_WEAPONS and game.DRAFT_SECONDARIES (plus the Lama),
-- so new weapons show up by themselves. Numbers are measured, not estimated.
package.path = "client/?.lua;" .. package.path
local game = require "sim.game"

local only, md = {}, nil
do
	local i = 1
	while arg[i] do
		if arg[i] == "--md" then md = arg[i + 1]; i = i + 2 else only[#only + 1] = arg[i]; i = i + 1 end
	end
end

local list = { "sword" }
for _, w in ipairs(game.DRAFT_SECONDARIES) do list[#list + 1] = w end
for _, w in ipairs(game.CRATE_WEAPONS) do list[#list + 1] = w end
if #only > 0 then list = only end

local function sky_spot(q, x0, w)
	for y = game.WORLD_H - 60, 100, -4 do
		local free = true
		for x = x0 - w, x0 + w, 4 do
			if q:robot_collides(x, y) or q:robot_collides(x, y - 40) then free = false; break end
		end
		if free then return y end
	end
end

local function place(rb, x, y)
	rb.x, rb.y, rb.vx, rb.vy, rb.grounded, rb.knocked = x, y, 0, 0, false, false
end

-- One shot: returns hp lost by the target and its displacement, or nil if the weapon can't fire
local function shot(w, dist, angle, power)
	local opts = { ammo = {}, hp = 1000 }
	if game.SECONDARY[w] and w ~= "sword" then opts.secondary = w else opts.ammo[w] = 1 end
	local q = game.new(42, "pavimento", opts)
	for _ = 1, 60 do q:step() end
	local a, b = q.robots[1], q.robots[2]
	-- each on the floor at its own x (the sky would add fall damage)
	local function floor_y(x)
		for y = 0, game.WORLD_H, 2 do if not q:robot_collides(x, y) then return y end end
	end
	local ax, bx = 960 - dist / 2, 960 + dist / 2
	place(a, ax, floor_y(ax))
	place(b, bx, floor_y(bx))
	a.grounded, b.grounded = true, true
	local x0, y0, hp = b.x, b.y, b.hp
	q:step({ fire = { angle = angle, power = power, weapon = w } })
	local fired = q.projectile ~= nil or a.recoil or a.swinging or q.melee ~= nil
	-- until the projectile is gone (the Uovo has a fuse) and 60 ticks after, at most 900
	local after = 0
	for _ = 1, 900 do
		q:step()
		if not q.projectile then after = after + 1 end
		if after >= 60 then break end
	end
	return hp - b.hp, math.sqrt((b.x - x0) ^ 2 + (b.y - y0) ^ 2), b.dead, fired
end

local out = {}
local function p(s) out[#out + 1] = s; print(s) end
p("| Arma | Danno max (1 colpo) | Dove | Gittata | Colpi per uccidere da 100 | Spinta max (px) |")
p("|---|---|---|---|---|---|")
for _, w in ipairs(list) do
	local best, bd, ba, bp, reach, push, any = 0, 0, 0, 0, 0, 0, false
	for _, dist in ipairs({ 30, 50, 80, 120, 180, 260, 360, 460, 600 }) do
		for _, deg in ipairs({ -80, -65, -50, -35, -20, -10, -5, 0, 5, 10, 20, 35, 50, 65, 80 }) do
			for _, pw in ipairs({ 0.3, 0.6, 1 }) do
				local ok, dmg, mv = pcall(shot, w, dist, math.rad(deg), pw)
				if ok and dmg then
					any = true
					if dmg > 0 and dist > reach then reach = dist end
					if dmg > best then best, bd, ba, bp = dmg, dist, deg, pw end
					if mv > push then push = mv end
				end
			end
		end
	end
	if any then
		p(string.format("| %s | %.1f | %dpx, %d°, forza %.1f | %dpx | %s | %d |", w, best, bd, ba, bp, reach,
			best > 0 and tostring(math.ceil(100 / best)) or "-", push))
	else
		p("| " .. w .. " | NON VALUTATO: non spara in questa prova | | | | |")
	end
end
if md then local f = assert(io.open(md, "w")); f:write(table.concat(out, "\n") .. "\n"); f:close() end
