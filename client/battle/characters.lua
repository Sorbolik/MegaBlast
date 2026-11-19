-- Each character's own animations, pivots and grips (battle/characters/<name>/,
-- made with the animation editor tools/animazioni): changing one never changes
-- another. battle/scoria.lua uses those of the character skin worn
-- (battle/skins.lua, category personaggio). A new character: its folder with the
-- three files (the editor copies them from another one) and its line here.
-- Its hitbox is in sim/body.lua.
return {
	apprendista_nuovo = {
		animations = require "battle.characters.apprendista_nuovo.animations",
		pivots = require "battle.characters.apprendista_nuovo.pivots",
		grips = require "battle.characters.apprendista_nuovo.grips",
	},
	apprendista = {
		animations = require "battle.characters.apprendista.animations",
		pivots = require "battle.characters.apprendista.pivots",
		grips = require "battle.characters.apprendista.grips",
	},
	favilla = {
		animations = require "battle.characters.favilla.animations",
		pivots = require "battle.characters.favilla.pivots",
		grips = require "battle.characters.favilla.grips",
	},
}
