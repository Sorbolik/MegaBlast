-- The full-screen background of a menu: the plain dark of ui.background, on
-- any proportion (ui/screen.lua). Each menu draws its own scene over it, the
-- rays and its accent (kit.scene, ui/kit.lua): the themes that were here
-- (docs/sfondi_menu.md) went away with the "Raggi" interface (11 Nov).
--
--   local backdrop = require "ui.backdrop"
--   local n = backdrop.new()   -- the root node: gui.delete_node(n) removes it all

local ui = require "ui.ui"

local M = {}

function M.new(parent)
	return ui.background(parent)
end

return M
