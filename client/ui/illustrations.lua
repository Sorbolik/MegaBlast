-- The mission illustrations (WB-015, Sergio 4 Nov: on the mission card and
-- full screen when the mission opens). JPEGs in /paintings/missions/ (custom
-- resources, loaded only when they are shown, not kept in an atlas): <id>.jpg
-- at 1280 x 720 for the opening, <id>_carta.jpg for the card. A mission
-- without its files simply has no illustration. Client only.
--
--   local ill = require "ui.illustrations"
--   local tex = ill.texture(id, "carta" | "tavola")  -- the gui texture name, or nil
--   ill.release(id, kind)                         -- when nothing shows it anymore

local M = {}

-- the textures made, by name, and how many nodes use them
local made = {}

local function name_of(id, kind)
	return "ill_" .. id .. (kind == "carta" and "_carta" or "")
end

-- The missions that have one (strumenti/grafica/illustrazioni.py writes the files)
M.MISSIONS = {
	primi_passi = true, lanciarune = true, turno = true, tempo = true, spostano = true,
	attrezzi = true,
}

function M.has(id)
	return M.MISSIONS[id] == true
end

function M.texture(id, kind)
	local key = name_of(id, kind)
	if made[key] then
		made[key] = made[key] + 1
		return key
	end
	if not M.has(id) then return nil end
	local data = sys.load_resource("/paintings/missions/" .. key:sub(5) .. ".jpg")
	if not data then return nil end
	local img = image.load(data)
	if not img then return nil end
	if not gui.new_texture(key, img.width, img.height, img.type, img.buffer) then return nil end
	made[key] = 1
	return key
end

function M.release(id, kind)
	local key = name_of(id, kind)
	if not made[key] then return end
	made[key] = made[key] - 1
	if made[key] <= 0 then
		gui.delete_texture(key)
		made[key] = nil
	end
end

return M
