-- The pictures of the CAMPAGNA, JPEGs in /paintings/ (custom resources,
-- loaded only when they are shown, not kept in an atlas). The missions: the
-- miniature of their map (Sergio, 6 Nov: no paintings on the missions, too
-- much lava; tools/grafica/miniature_missioni.py writes them) in
-- /paintings/missions/: <id>.jpg for the postcard, <id>_carta.jpg for the
-- card on the CAMPAGNA's board, <id>_finale.jpg for the strip of a chapter's
-- final. The story's panels are the only paintings. Client only.
--
--   local ill = require "ui.illustrations"
--   local tex = ill.texture(id, "carta" | "tavola" | "finale")  -- the gui texture name, or nil (no file)
--   ill.release(id, kind)                         -- when nothing shows it anymore
--   local tex = ill.story(id)  /  ill.story_release(id)   -- a panel of the story

local M = {}

-- the textures made, by name, and how many nodes use them
local made = {}
-- and their size in pixels: { w, h }
local dims = {}

local function name_of(id, kind)
	return "ill_" .. id .. ((kind == "carta" or kind == "finale") and "_" .. kind or "")
end

-- a JPEG of /paintings/ made a gui texture called key (shared: counted)
local function load(key, path)
	if made[key] then
		made[key] = made[key] + 1
		return key, dims[key]
	end
	local data = sys.load_resource(path)
	if not data then return nil end
	local img = image.load(data)
	if not img then return nil end
	if not gui.new_texture(key, img.width, img.height, img.type, img.buffer) then return nil end
	made[key] = 1
	dims[key] = { w = img.width, h = img.height }
	return key, dims[key]
end

local function release(key)
	if not made[key] then return end
	made[key] = made[key] - 1
	if made[key] <= 0 then
		gui.delete_texture(key)
		made[key], dims[key] = nil, nil
	end
end

function M.texture(id, kind)
	local key = name_of(id, kind)
	return load(key, "/paintings/missions/" .. key:sub(5) .. ".jpg")
end

function M.release(id, kind)
	release(name_of(id, kind))
end

-- The story's panels (WB-012, WB-017; ui/story.lua): /paintings/story/<id>.jpg
-- at the size Codex drew them, so each keeps its own shape (wide or square):
-- the texture's name and its size { w, h }
function M.story(id)
	return load("storia_" .. id, "/paintings/story/" .. id .. ".jpg")
end

function M.story_release(id)
	release("storia_" .. id)
end

return M
