extends Node
class_name PuzzleManager
## Drives one dimension's unique puzzle: validates the player's actions, gives
## progress/failure feedback, and reports success. Every dimension uses a
## different `type`, so each realm plays differently.

signal solved
signal failed
signal progress(done: int, total: int)
signal message(text: String)

const SCENE := "res://scenes/puzzles/puzzle_object.tscn"

const PROP_LEVER := "res://Assets/generated/prop_lever.png"
const PROP_VALVE := "res://Assets/generated/prop_valve.png"
const PROP_PEDESTAL := "res://Assets/generated/prop_pedestal.png"
const PROP_CRYSTAL := "res://Assets/generated/prop_crystal.png"

var cfg: Dictionary = {}
var level_index := 0
var type := ""
var objects: Array[PuzzleObject] = []
var order: Array = []
var solution: Array = []
var next_index := 0
var _solved := false
var required_cherries := 0


func configure(_cfg: Dictionary, parent: Node2D, _level_index: int) -> void:
	cfg = _cfg
	level_index = _level_index
	type = String(cfg.get("type", "sequence"))
	order = cfg.get("order", [])
	solution = cfg.get("solution", [])
	required_cherries = int(cfg.get("required_cherries", 0))
	for o in cfg.get("objects", []):
		var obj: PuzzleObject = load(SCENE).instantiate()
		obj.configure(_kind_for(), int(o.id), _tex_for(), String(o.get("symbol", "")),
			o.get("color", Color.WHITE), int(o.get("states", 3)), String(o.get("key", "")))
		var pos: Array = o.pos
		obj.position = Vector2(float(pos[0]), float(pos[1]))
		parent.add_child(obj)
		obj.interacted.connect(_on_interacted)
		objects.append(obj)
	_emit_progress()


func title() -> String:
	return String(cfg.get("title", "Puzzle"))


func hint() -> String:
	return String(cfg.get("hint", ""))


func total() -> int:
	if type == "combination" or type == "collect":
		return objects.size()
	return order.size()


func is_solved() -> bool:
	return _solved


func _kind_for() -> PuzzleObject.Kind:
	match type:
		"combination":
			return PuzzleObject.Kind.VALVE
		"pedestals":
			return PuzzleObject.Kind.PEDESTAL
		"collect":
			return PuzzleObject.Kind.CRYSTAL
		"sequence":
			# Jungle uses crystal "living stones", Emberfall uses levers.
			return PuzzleObject.Kind.CRYSTAL if cfg.get("flavor", "") == "plants" else PuzzleObject.Kind.LEVER
	return PuzzleObject.Kind.LEVER


func _tex_for() -> String:
	match type:
		"combination":
			return PROP_VALVE
		"pedestals":
			return PROP_PEDESTAL
		"collect":
			return PROP_CRYSTAL
		"sequence":
			return PROP_CRYSTAL if cfg.get("flavor", "") == "plants" else PROP_LEVER
	return PROP_LEVER


func _on_interacted(obj: PuzzleObject) -> void:
	if _solved:
		return
	if required_cherries > 0 and GameState.level_cherries(level_index) < required_cherries:
		AudioManager.play_sfx("puzzle_fail")
		message.emit("The mechanism slumbers - gather %d cherries first (%d so far)."
			% [required_cherries, GameState.level_cherries(level_index)])
		return
	match type:
		"collect":
			_handle_collect(obj)
		"combination":
			_handle_combination(obj)
		"pedestals":
			_handle_pedestals(obj)
		_:
			_handle_sequence(obj)


## Simple, forgiving puzzle: switch on every object in any order.
func _handle_collect(obj: PuzzleObject) -> void:
	if obj.active:
		return
	obj.set_active(true)
	AudioManager.play_sfx("puzzle_ok")
	var lit := _lit_count()
	_emit_progress()
	if lit >= objects.size():
		_finish()
	else:
		message.emit("Crystal lit.  %d / %d" % [lit, objects.size()])


func _lit_count() -> int:
	var n := 0
	for o in objects:
		if o.active:
			n += 1
	return n


func _handle_sequence(obj: PuzzleObject) -> void:
	if obj.active or next_index >= order.size():
		return
	if obj.pid == int(order[next_index]):
		obj.set_active(true)
		next_index += 1
		AudioManager.play_sfx("puzzle_ok")
		_emit_progress()
		if next_index >= order.size():
			_finish()
		else:
			message.emit("%s answers.  %d / %d" % [obj.symbol, next_index, order.size()])
	else:
		_fail()


func _handle_pedestals(obj: PuzzleObject) -> void:
	if obj.active:
		return
	if obj.required_key != "" and not GameState.has_key(obj.required_key):
		AudioManager.play_sfx("puzzle_fail")
		message.emit("This pedestal thirsts for the %s." % Dimensions.key_name(obj.required_key))
		return
	_handle_sequence(obj)


func _handle_combination(obj: PuzzleObject) -> void:
	obj.state = (obj.state + 1) % obj.states
	obj.refresh_state()
	AudioManager.play_sfx("valve", randf_range(0.95, 1.1))
	var matched := 0
	for o in objects:
		var want := int(solution[o.pid]) if o.pid < solution.size() else -1
		if o.state == want:
			matched += 1
	_emit_progress()
	if matched == objects.size():
		for o in objects:
			o.set_active(true)
		_finish()
	else:
		message.emit("Tide valves aligned:  %d / %d" % [matched, objects.size()])


func _fail() -> void:
	AudioManager.play_sfx("puzzle_fail")
	for o in objects:
		o.set_active(false)
	next_index = 0
	failed.emit()
	message.emit("The mechanism rejects that order - it resets. Think again.")
	_emit_progress()


func _finish() -> void:
	_solved = true
	AudioManager.play_sfx("puzzle_ok", 0.85)
	solved.emit()


func _emit_progress() -> void:
	var done := next_index
	if type == "combination":
		done = 0
		for o in objects:
			var want := int(solution[o.pid]) if o.pid < solution.size() else -1
			if o.state == want:
				done += 1
	elif type == "collect":
		done = _lit_count()
	GameState.set_puzzle_progress(level_index, done, total())
	progress.emit(done, total())
