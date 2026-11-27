-- What the game asks of the phone (Sergio, 21 Nov): the screen never dims while
-- the game is open, the sound goes quiet in the background (a call, another
-- app), the vibrations (with their switch in IMPOSTAZIONI) and the frame rate:
-- matches and the Fornace's pours at the screen's best (90/120 Hz where it has them), menus at 60 and
-- at 30 when nobody touches them for a while, so the phone doesn't heat up in
-- the home. Android's game mode "risparmio batteria" caps matches at 60.
-- On Android through client/vibra (Java), in the browser navigator.vibrate;
-- on the computer only the vibrations' SIMULA line.
--
--   local phone = require "main.phone"
--   phone.init()                   -- once, at start
--   phone.vibration(on)            -- the switch (profile setting "vibrazione")
--   phone.tap()                    -- the micro-vibration of the controls
--   phone.blast(r)                 -- an explosion of radius r
--   phone.input()                  -- someone touched: the menus wake up
--   phone.update(dt, in_match)     -- every frame

local M = {}

-- in the simulator the vibrations are written to the log (tools/simula)
local SIMULATE = sys.get_config_int("megablast.simula", 0) == 1

-- the frame rates (0: every frame of the screen)
local MATCH, MATCH_BATTERY, MENU, MENU_IDLE = 0, 60, 60, 30
-- seconds without a touch before the menus go to MENU_IDLE
local IDLE_AFTER = 12
-- Android's game modes (client/vibra, GameManager)
local BATTERY = 3

local mobile = false
local on = true
local idle, hz = 0, nil
local game_mode = 0

local function read_game_mode()
	if vibra then game_mode = vibra.modo_gioco() end
end

function M.init()
	local name = sys.get_sys_info().system_name
	mobile = name == "Android" or name == "iPhone OS"
	window.set_dim_mode(window.DIMMING_OFF)
	if vibra then vibra.alta_frequenza() end
	read_game_mode()
	window.set_listener(function(_, event)
		if event == window.WINDOW_EVENT_FOCUS_LOST or event == window.WINDOW_EVENT_ICONIFIED then
			sound.set_group_gain("master", 0)
		elseif event == window.WINDOW_EVENT_FOCUS_GAINED or event == window.WINDOW_EVENT_DEICONIFIED then
			sound.set_group_gain("master", 1)
			-- (the mode may have been changed from the phone's game panel meanwhile)
			read_game_mode()
			idle = 0
		end
	end)
end

function M.vibration(yes) on = yes end

function M.tap()
	if not on then return end
	if vibra then
		vibra.tocco()
	elseif html5 then
		html5.run("navigator.vibrate && navigator.vibrate(12)")
	elseif SIMULATE then
		print("SIMULA evento vibra")
	end
end

-- longer and stronger with the blast (radius 20 to 60 and more)
function M.blast(r)
	if not on then return end
	local k = math.min(1, math.max(0, (r - 15) / 45))
	local ms, strength = math.floor(25 + 45 * k), math.floor(70 + 150 * k)
	if vibra then
		vibra.colpo(ms, strength)
	elseif html5 then
		html5.run("navigator.vibrate && navigator.vibrate(" .. ms .. ")")
	elseif SIMULATE then
		print("SIMULA evento vibra_colpo " .. ms)
	end
end

function M.input() idle = 0 end

function M.update(dt, in_match)
	if not mobile then return end
	idle = idle + dt
	local want
	if in_match then
		want = game_mode == BATTERY and MATCH_BATTERY or MATCH
	else
		want = (idle > IDLE_AFTER or game_mode == BATTERY) and MENU_IDLE or MENU
	end
	if want ~= hz then
		hz = want
		sys.set_update_frequency(hz)
	end
end

return M
