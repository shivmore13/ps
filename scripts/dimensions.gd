class_name Dimensions
extends RefCounted
## Metadata for the four dimensions: their names, dimensional keys, and the
## configuration for each dimension's unique puzzle.
##
## The heavy layout data (terrain, hazards, cherries, boss, portal) lives in
## Levels; this file adds the story/puzzle layer on top of it.

## The dimensional keys, in the order the King collects them.
const KEY_EMBERT := "ember"
const KEY_TIDE := "tide"
const KEY_THORN := "thorn"
const KEY_VOIDK := "void"

const KEY_NAMES := {
	"ember": "Ember Key",
	"tide": "Tide Key",
	"thorn": "Thorn Key",
	"void": "Void Key",
}

const KEY_COLORS := {
	"ember": Color(1.0, 0.45, 0.15),
	"tide": Color(0.3, 0.8, 1.0),
	"thorn": Color(0.5, 1.0, 0.4),
	"void": Color(0.72, 0.4, 1.0),
}


static func key_name(id: String) -> String:
	return String(KEY_NAMES.get(id, id))


static func key_color(id: String) -> Color:
	return KEY_COLORS.get(id, Color.WHITE)


## Per-dimension metadata. Puzzle object positions are in world pixels.
const DATA := [
	# ------------------------------- EMBERFALL -------------------------------
	{
		"dimension": "Emberfall",
		"subtitle": "The Lava Kingdom",
		"boss_key": "ember",
		"key_pos": [2680, 470],
		"puzzle": {
			"type": "sequence",
			"title": "The Three Ember Seals",
			"hint": "The furnace demands the Ember Seals be roused in rune order:  I  then  II  then  III.",
			"order": [0, 1, 2],
			"objects": [
				{"id": 0, "pos": [1180, 470], "symbol": "I"},
				{"id": 1, "pos": [1660, 430], "symbol": "II"},
				{"id": 2, "pos": [2140, 425], "symbol": "III"},
			],
		},
	},
	# ------------------------------- ABYSSARA --------------------------------
	{
		"dimension": "Abyssara",
		"subtitle": "The Sunken Ocean Realm",
		"boss_key": "tide",
		"key_pos": [3020, 490],
		"puzzle": {
			"type": "combination",
			"title": "The Tidal Clock",
			"hint": "Set the three tide valves to match the markers on the temple wall:  III - I - II.",
			"solution": [2, 0, 1],
			"objects": [
				{"id": 0, "pos": [1040, 470], "states": 3},
				{"id": 1, "pos": [1760, 470], "states": 3},
				{"id": 2, "pos": [2440, 400], "states": 3},
			],
		},
	},
	# ------------------------------- THORNWILD -------------------------------
	{
		"dimension": "Thornwild",
		"subtitle": "The Ancient Jungle",
		"boss_key": "thorn",
		"key_pos": [3020, 470],
		"puzzle": {
			"type": "sequence",
			"title": "The Living Temple",
			"hint": "The stone tablet reads: awaken the plants in the order  AMBER, GREEN, BLUE.",
			"order": [1, 0, 2],
			"objects": [
				{"id": 0, "pos": [1080, 470], "symbol": "GREEN", "color": Color(0.4, 1.0, 0.4)},
				{"id": 1, "pos": [1780, 440], "symbol": "AMBER", "color": Color(1.0, 0.75, 0.25)},
				{"id": 2, "pos": [2480, 380], "symbol": "BLUE", "color": Color(0.45, 0.7, 1.0)},
			],
		},
	},
	# ---------------------------- FRACTURED VOID -----------------------------
	{
		"dimension": "The Fractured Void",
		"subtitle": "Varkhos's Fortress",
		"boss_key": "",  # the Void Key comes from the puzzle, not the boss
		"key_pos": [1620, 200],  # rafters route, reached by reversing gravity
		"queen": true,
		"puzzle": {
			"type": "collect",
			"title": "The Convergence Crystals",
			"hint": "Wake all four Convergence Crystals - walk up to each and press E. Any order works; the fortress gate opens once all four glow.",
			"objects": [
				{"id": 0, "pos": [1000, 570]},
				{"id": 1, "pos": [1450, 570]},
				{"id": 2, "pos": [1900, 570]},
				{"id": 3, "pos": [2350, 570]},
			],
		},
	},
]


static func get_data(index: int) -> Dictionary:
	return DATA[clampi(index, 0, DATA.size() - 1)]


static func dimension_name(index: int) -> String:
	return String(get_data(index).get("dimension", ""))


static func puzzle_for(index: int) -> Dictionary:
	return get_data(index).get("puzzle", {})
