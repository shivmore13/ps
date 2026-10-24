class_name StoryData
extends RefCounted
## All original dialogue and cinematic shot lists for ORPHOX: The Kingdom
## Beyond Dimensions.
##
## A "shot" is one frame of a cinematic:
##   bg     : res:// background texture path (optional)
##   sprites: array of {tex, x, y, scale, flip} character sprites (optional)
##   speaker: name shown in the dialogue box
##   text   : the line of dialogue / narration
##   title  : optional large centred title instead of a dialogue box

const KING_TEX := "res://Assets/generated/king_full.png"
const QUEEN_IDLE := "res://Assets/generated/queen_idle.png"
const QUEEN_WORRIED := "res://Assets/generated/queen_worried.png"
const QUEEN_HAPPY := "res://Assets/generated/queen_happy.png"
const VARKHOS := "res://Assets/generated/boss_varkhos.png"
const CAGE := "res://Assets/generated/prop_cage.png"
const KING_IDLE := "res://Assets/generated/king_full.png"

const BG_CASTLE := "res://Assets/generated/title_bg.png"
const BG_LAVA := "res://Assets/generated/bg_lava.png"
const BG_VOID := "res://Assets/generated/bg_void.png"
const BG_JUNGLE := "res://Assets/generated/bg_jungle.png"
const BG_OCEAN := "res://Assets/generated/bg_ocean.png"


## The opening cinematic: the kidnapping and the King's resolve.
static func intro() -> Array:
	return [
		{"title": "ORPHOX", "sub": "The Kingdom Beyond Dimensions"},
		{"bg": BG_CASTLE, "speaker": "Narrator",
		 "text": "Long ago the Fox Kingdom prospered, kept in harmony by the Fox King and the Fox Queen, whose ancient power joined the worlds together."},
		{"bg": BG_CASTLE, "sprites": [{"tex": VARKHOS, "x": 900, "y": 380, "scale": 1.6, "flip": true}],
		 "speaker": "Narrator",
		 "text": "Then came VARKHOS, the Void Emperor, who coveted the Queen's power to conquer every dimension."},
		{"bg": BG_CASTLE, "sprites": [
			{"tex": VARKHOS, "x": 860, "y": 380, "scale": 1.6, "flip": true},
			{"tex": QUEEN_WORRIED, "x": 380, "y": 420, "scale": 2.2}],
		 "speaker": "Varkhos",
		 "text": 'Your little kingdom ends here, little queen. Your light will open my gates to every world.'},
		{"bg": BG_CASTLE, "sprites": [{"tex": QUEEN_WORRIED, "x": 620, "y": 420, "scale": 2.4}],
		 "speaker": "Fox Queen",
		 "text": 'My King... do not lose hope. Find the old portals. Find me.'},
		{"bg": BG_LAVA, "sprites": [{"tex": KING_IDLE, "x": 400, "y": 430, "scale": 2.2}],
		 "speaker": "Fox King",
		 "text": "The invaders took my crown's peace, my royal blade, and my queen. But the realm left me one gift: the ancient portals still burn."},
		{"bg": BG_VOID, "sprites": [{"tex": KING_IDLE, "x": 400, "y": 430, "scale": 2.2}],
		 "speaker": "Fox King",
		 "text": "Four dimensions stand between me and her. Four guardians. Four keys. I will take them all - and then I will take back my kingdom."},
	]


## Short clue shown after a guardian falls, revealing part of Varkhos's plan.
static func clue(level_index: int) -> Array:
	match level_index:
		0:
			return [
				{"bg": BG_LAVA, "speaker": "Fox King",
				 "text": "Ignar's armour cracks... and from it falls the Ember Key. Its runes murmur: 'Four keys bind the prison.'"},
				{"bg": BG_LAVA, "speaker": "Narrator",
				 "text": "The guardians are not conquerors. They are jailers - each one holding a key that keeps the Queen's cage sealed."},
			]
		1:
			return [
				{"bg": BG_OCEAN, "speaker": "Fox King",
				 "text": "The Tide Key hums in my paw. In Thalassor's temple I found a draining rune - Varkhos is pouring the Queen's power into his gates."},
				{"bg": BG_OCEAN, "speaker": "Narrator",
				 "text": "For every realm he frees, the prison around the Queen grows stronger. The King must hurry."},
			]
		2:
			return [
				{"bg": BG_JUNGLE, "sprites": [{"tex": KING_IDLE, "x": 380, "y": 430, "scale": 2.2}],
				 "speaker": "Fox King",
				 "text": "The Thorn Key is mine. Razorclaw's lair held carvings of a cage - and of a queen standing inside it."},
				{"bg": BG_VOID, "sprites": [{"tex": QUEEN_WORRIED, "x": 640, "y": 430, "scale": 2.2}],
				 "speaker": "Fox Queen (echo)",
				 "text": '...hold on, my King. The Emperor\'s fortress is close. I can feel your light.'},
			]
	return []


## Cinematic reveal of the Queen's prison inside the Void fortress.
static func prison() -> Array:
	return [
		{"bg": BG_VOID, "speaker": "Narrator",
		 "text": "Beyond the shattered gates, Varkhos's throne hall sprawls across broken space. And there, behind the throne, burns a cage of chained light."},
		{"bg": BG_VOID, "sprites": [
			{"tex": QUEEN_WORRIED, "x": 640, "y": 380, "scale": 2.1},
			{"tex": CAGE, "x": 640, "y": 300, "scale": 2.0}],
		 "speaker": "Fox Queen",
		 "text": 'My King! You came... but beware - Varkhos feeds on the cage. Break it only after you break him.'},
		{"bg": BG_VOID, "sprites": [{"tex": KING_IDLE, "x": 380, "y": 430, "scale": 2.2}],
		 "speaker": "Fox King",
		 "text": 'Then he falls first. I have walked four worlds to reach you, my love - I will not stop one step short.'},
	]


## The full ending: Varkhos's fall, the cage breaking, the reunion, the kingdom.
static func ending() -> Array:
	return [
		{"bg": BG_VOID, "sprites": [{"tex": VARKHOS, "x": 640, "y": 360, "scale": 1.8}],
		 "speaker": "Varkhos",
		 "text": 'Impossible... my dimensions... my empire... crumbling...'},
		{"bg": BG_VOID, "sprites": [{"tex": CAGE, "x": 640, "y": 300, "scale": 2.0}],
		 "speaker": "Narrator",
		 "text": "With their master broken, the dimensional chains lose their grip. The cage splits open in a burst of light."},
		{"bg": BG_VOID, "sprites": [{"tex": QUEEN_HAPPY, "x": 660, "y": 400, "scale": 2.2}],
		 "speaker": "Fox Queen",
		 "text": 'You did it. You truly crossed every realm...'},
		{"bg": BG_VOID, "sprites": [
			{"tex": KING_IDLE, "x": 500, "y": 430, "scale": 2.2},
			{"tex": QUEEN_HAPPY, "x": 780, "y": 430, "scale": 2.2}],
		 "speaker": "Fox King",
		 "text": 'I am the King, and you are my kingdom\'s heart. I would cross a thousand voids for you.'},
		{"bg": BG_CASTLE, "sprites": [
			{"tex": KING_IDLE, "x": 520, "y": 430, "scale": 2.4},
			{"tex": QUEEN_HAPPY, "x": 760, "y": 430, "scale": 2.4}],
		 "speaker": "Fox Queen",
		 "text": 'Look - the four portals are steady again. Emberfall, Abyssara, Thornwild, and the Void, all at peace.'},
		{"bg": BG_CASTLE, "sprites": [
			{"tex": KING_IDLE, "x": 560, "y": 430, "scale": 2.6},
			{"tex": QUEEN_HAPPY, "x": 720, "y": 430, "scale": 2.6}],
		 "speaker": "Fox King",
		 "text": 'Then come home, my queen. Let the kingdom be whole again.'},
	]


## Per-dimension opening line, shown when a realm begins.
static func dimension_intro(level_index: int) -> Array:
	match level_index:
		0:
			return [{"bg": BG_LAVA, "speaker": "Fox King",
				"text": "Emberfall. The air burns and the guardian's furnace never cools. I must earn the first key."}]
		1:
			return [{"bg": BG_OCEAN, "speaker": "Fox King",
				"text": "Abyssara. This temple sank before my grandfather drew breath. Its tide valves still answer to a careful hand."}]
		2:
			return [{"bg": BG_JUNGLE, "speaker": "Fox King",
				"text": "Thornwild. The old temple has grown wild, and its roots remember every oath. I must wake the living stones."}]
		3:
			return [{"bg": BG_VOID, "speaker": "Fox King",
				"text": "The Fractured Void. Four convergence crystals light the way to Varkhos's gate - and behind it, the Queen. This ends today."}]
	return []
