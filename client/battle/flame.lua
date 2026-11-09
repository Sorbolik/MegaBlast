-- The live flames: the Apprendista's little flame and Favilla's flame hair,
-- bent in real time by battle/flame.fp (no sprite sheets). The drawn image is
-- loaded on its own (a custom resource, not the atlas), so in the shader its
-- coordinates go from 0 to 1 over the whole image.
--
--   local flame = require "battle.flame"
--   local key = flame.texture(img)        -- the gui texture of a piece image, or nil (not a live one)
--   local ox, oy, w, h = flame.frame(img, p)   -- the node around piece p (drawing units, like p)
--   flame.color(c, t, img, white)         -- the node's color: time, kind, hit flash
--
-- Client only (battle/scoria.lua).

local M = {}

-- the Favilla hair: the node is larger than the head by PAD on every side
-- (the shader draws the image inside it), so the locks can sway past the edge
-- of the image without being cut
M.PAD = 0.06

-- The live images, by piece image name (battle/skins.lua). box: where the
-- flame is in the image (x, y from the top left, w, h, in pixels; the rest is
-- empty, room to sway); hair: the whole head, the face stays still
M.ART = {
	apprendista_fiamma = { file = "/paintings/flame/apprendista.png", size = 256, box = { 57, 52, 142, 200 } },
}
for _, face in ipairs({ "", "_arrabbiata", "_colpita", "_felice", "_ko", "_mira", "_paura", "_provocazione", "_sconfitta" }) do
	local img = "favilla_testa" .. face .. "_1"
	M.ART[img] = { file = "/assets/skins/" .. img .. ".png", hair = true }
end

-- the textures made (the battle gui lives as long as the game)
local made = {}

function M.texture(img)
	local a = M.ART[img]
	if not a then return nil end
	local key = "fiamma_" .. img
	if made[key] then return key end
	if not (sys and image and gui.new_texture) then return nil end
	local data = sys.load_resource(a.file)
	local pic = data and image.load(data, { premultiply_alpha = true })
	if not pic then return nil end
	local ok, code = gui.new_texture(key, pic.width, pic.height, pic.type, pic.buffer)
	if not ok and code ~= gui.RESULT_TEXTURE_ALREADY_EXISTS then return nil end
	made[key] = true
	return key
end

-- the node of piece p: center offset and size, in drawing units
function M.frame(img, p)
	local a = M.ART[img]
	if a.hair then
		local f = 1 / (1 - 2 * M.PAD)
		return 0, 0, p.w * f, p.h * f
	end
	local s, b = a.size, a.box
	local fx, fy = p.w / b[3], p.h / b[4]
	return (s / 2 - (b[1] + b[3] / 2)) * fx, ((b[2] + b[4] / 2) - s / 2) * fy, s * fx, s * fy
end

-- the color that drives the shader: r the fraction of the second, g the whole
-- seconds (all the waves repeat every 16) plus 128 for the hair, b how white
-- (1 normal, 0 all white)
function M.color(c, t, img, white)
	t = t % 16
	local whole = math.floor(t)
	c.x = t - whole
	c.y = (whole + (M.ART[img].hair and 128 or 0)) / 255
	c.z = 1 - white
	c.w = 1
	return c
end

return M
