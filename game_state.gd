extends Node
## Autoload singleton (registered as `GameState`).
## Holds all progression data for a run and persists it via ConfigFile.
## Health, cherries, weapons, unlocked levels, defeated bosses and score live here
## so every level scene and the UI observe the same source of truth.

signal hearts_changed(hearts: int, max_hearts: int)
signal cherries_changed(total: int)
signal gun_changed(unlocked: bool)
signal ammo_changed(ammo: int)
signal ability_changed(ability_id: String)
signal boss_state_changed(level_index: int, defeated: bool)
signal keys_changed(keys: Dictionary)
signal puzzle_changed(level_index: int, done: int, total: int)
signal queen_changed(rescued: bool)

const MAX_HEARTS := 3
const SAVE_PATH := "user://orphox_save.cfg"
const START_AMMO := 0
const MAX_AMMO := 30

var hearts: int = MAX_HEARTS
var max_hearts: int = MAX_HEARTS
var total_cherries: int = 0
var cherries_per_level: Dictionary = {}
var gun_unlocked: bool = false
var ammo: int = 0
var current_level: int = 0
var checkpoint_level: int = 0
var bosses_defeated: Dictionary = {}
var levels_unlocked: int = 1
var current_ability: String = ""
var score: int = 0
var play_seconds: float = 0.0

## Campaign progression added for "The Kingdom Beyond Dimensions".
var keys: Dictionary = {}          # key id -> true
var queen_rescued: bool = false
var puzzle_progress: Dictionary = {}  # level_index -> [done, total]
var seen_intro: Dictionary = {}       # level_index -> true (session only)
var campaign_complete: bool = false
var play_start_msec: int = 0


func _ready() -> void:
	# Ensure a clean initial run; a save is only applied when asked for.
	reset_run()


## Reset everything for a brand new game.
func reset_run() -> void:
	hearts = MAX_HEARTS
	max_hearts = MAX_HEARTS
	total_cherries = 0
	cherries_per_level = {}
	gun_unlocked = false
	ammo = 0
	current_level = 0
	checkpoint_level = 0
	bosses_defeated = {}
	levels_unlocked = 1
	current_ability = ""
	score = 0
	play_seconds = 0.0
	keys = {}
	queen_rescued = false
	puzzle_progress = {}
	seen_intro = {}
	campaign_complete = false
	play_start_msec = Time.get_ticks_msec()
	_emit_all()


func _emit_all() -> void:
	hearts_changed.emit(hearts, max_hearts)
	cherries_changed.emit(total_cherries)
	gun_changed.emit(gun_unlocked)
	ammo_changed.emit(ammo)
	ability_changed.emit(current_ability)
	keys_changed.emit(keys)


## ---- Level lifecycle -------------------------------------------------------

## Begin a level: refills hearts, arms the level ability, clears the gun.
func begin_level(index: int) -> void:
	current_level = clamp(index, 0, Levels.LEVELS.size() - 1)
	hearts = max_hearts
	gun_unlocked = false
	ammo = 0
	current_ability = Levels.ability_for(current_level)
	_emit_all()


func ability_name() -> String:
	return Levels.ability_display(current_ability)


## ---- Health ---------------------------------------------------------------

func damage(amount: int = 1) -> void:
	hearts = max(0, hearts - amount)
	hearts_changed.emit(hearts, max_hearts)


func heal(amount: int = 1) -> void:
	hearts = min(max_hearts, hearts + amount)
	hearts_changed.emit(hearts, max_hearts)


func is_dead() -> bool:
	return hearts <= 0


## ---- Collectibles & weapons ----------------------------------------------

func collect_cherry(level_index: int) -> void:
	total_cherries += 1
	var cur: int = int(cherries_per_level.get(level_index, 0))
	cherries_per_level[level_index] = cur + 1
	score += 100
	cherries_changed.emit(total_cherries)


func level_cherries(level_index: int) -> int:
	return int(cherries_per_level.get(level_index, 0))


func collect_gun(start_ammo: int = 15) -> void:
	gun_unlocked = true
	ammo = start_ammo
	gun_changed.emit(gun_unlocked)
	ammo_changed.emit(ammo)


func spend_ammo(n: int = 1) -> bool:
	if ammo < n:
		return false
	ammo -= n
	ammo_changed.emit(ammo)
	return true


func add_ammo(n: int) -> void:
	ammo = min(MAX_AMMO, ammo + n)
	ammo_changed.emit(ammo)


## ---- Dimensional keys -----------------------------------------------------

func collect_key(id: String) -> void:
	if id == "" or bool(keys.get(id, false)):
		return
	keys[id] = true
	score += 500
	keys_changed.emit(keys)


func has_key(id: String) -> bool:
	return bool(keys.get(id, false))


func key_count() -> int:
	return keys.size()


func rescue_queen() -> void:
	queen_rescued = true
	score += 2000
	queen_changed.emit(true)


## ---- Puzzle progress ------------------------------------------------------

func set_puzzle_progress(level_index: int, done: int, total: int) -> void:
	puzzle_progress[level_index] = [done, total]
	puzzle_changed.emit(level_index, done, total)


func puzzle_progress_for(level_index: int) -> Array:
	return puzzle_progress.get(level_index, [0, 0])


func elapsed_seconds() -> float:
	if play_start_msec <= 0:
		return 0.0
	return (Time.get_ticks_msec() - play_start_msec) / 1000.0


func intro_seen(level_index: int) -> bool:
	return bool(seen_intro.get(level_index, false))


func mark_intro_seen(level_index: int) -> void:
	seen_intro[level_index] = true


## ---- Bosses ---------------------------------------------------------------

func mark_boss_defeated(level_index: int) -> void:
	bosses_defeated[level_index] = true
	score += 1000
	boss_state_changed.emit(level_index, true)


func is_boss_defeated(level_index: int) -> bool:
	return bool(bosses_defeated.get(level_index, false))


func bosses_defeated_count() -> int:
	return bosses_defeated.size()


## ---- Progression ----------------------------------------------------------

func complete_level(level_index: int) -> void:
	levels_unlocked = max(levels_unlocked, min(Levels.LEVELS.size(), level_index + 2))
	checkpoint_level = level_index + 1
	save_game()


func is_last_level() -> bool:
	return current_level >= Levels.LEVELS.size() - 1


## ---- Save / Load ----------------------------------------------------------

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "total_cherries", total_cherries)
	cfg.set_value("progress", "score", score)
	cfg.set_value("progress", "levels_unlocked", levels_unlocked)
	cfg.set_value("progress", "checkpoint_level", checkpoint_level)
	cfg.set_value("progress", "bosses_defeated", bosses_defeated)
	cfg.set_value("progress", "cherries_per_level", cherries_per_level)
	cfg.set_value("progress", "keys", keys)
	cfg.set_value("progress", "queen_rescued", queen_rescued)
	cfg.set_value("progress", "puzzle_progress", puzzle_progress)
	cfg.set_value("progress", "campaign_complete", campaign_complete)
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("ORPHOX: could not save game (%d)" % err)


func load_game() -> bool:
	if not has_save():
		return false
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return false
	total_cherries = int(cfg.get_value("progress", "total_cherries", 0))
	score = int(cfg.get_value("progress", "score", 0))
	levels_unlocked = int(cfg.get_value("progress", "levels_unlocked", 1))
	checkpoint_level = int(cfg.get_value("progress", "checkpoint_level", 0))
	bosses_defeated = cfg.get_value("progress", "bosses_defeated", {})
	cherries_per_level = cfg.get_value("progress", "cherries_per_level", {})
	keys = cfg.get_value("progress", "keys", {})
	queen_rescued = bool(cfg.get_value("progress", "queen_rescued", false))
	puzzle_progress = cfg.get_value("progress", "puzzle_progress", {})
	campaign_complete = bool(cfg.get_value("progress", "campaign_complete", false))
	_emit_all()
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
