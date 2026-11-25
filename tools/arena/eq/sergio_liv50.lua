-- L'equipaggiamento di Sergio in una partita di ALLENAMENTO 2v2 difficile (22 nov, livello 50):
-- per tools/arena --eq, i bot si vestono come i suoi rivali (sim/loadout.lua rival)
return {
	gear = {
		chest = "corvo",
		cloak = "corvo",
		gloves = "vuoto",
		legs = "corvo",
		mask = "corvo"
	},
	liv = 50,
	lv = {
		chest = 30,
		cloak = 30,
		gloves = 30,
		legs = 30,
		mask = 30
	},
	sg = {
		chest = 3,
		cloak = 3,
		gloves = 3,
		legs = 3,
		mask = 3
	},
	tree = {
		armor = 20,
		forge = 5,
		pick = {
			armor = {
				["1"] = 1,
				["2"] = 1,
				["3"] = 1,
				["4"] = 1
			},
			forge = {
				["1"] = 2
			},
			wings = {
				["1"] = 1,
				["2"] = 2,
				["3"] = 1,
				["4"] = 1,
				["5"] = 1
			}
		},
		wings = 25
	},
	variant = "a"
}
