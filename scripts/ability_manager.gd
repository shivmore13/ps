extends Node
class_name AbilityManager
## Drives the anti-physics ability for the current realm.
##
## Each realm grants one ability. Activating it applies a real, timed effect to
## physics objects in the scene and then cleanly reverts it, guarding against
## softlocks (e.g. a hidden platform the fox is still standing on).

signal state_changed(display_name: String, active: bool, time_left: float, cooldown: float, ready: bool)

const DURATION := {
	"gravity_reverse": 7.0,
	"time_freeze": 4.5,
	"time_slow": 6.0,
}
const COOLDOWN := {
	"gravity_reverse": 4.0,
	"time_freeze": 6.0,
	"time_slow": 5.0,
}

var ability_id := ""
var active := false
var time_left := 0.0
var cooldown_left := 0.0
var fox: Fox


func _ready() -> void:
	fox = get_parent() as Fox
	if GameState.current_ability != "":
		setup(GameState.current_ability)


func setup(id: String) -> void:
	ability_id = id
	active = false
	time_left = 0.0
	cooldown_left = 0.0
	_emit()


func display_name() -> String:
	return Levels.ability_display(ability_id)


func is_ready() -> bool:
	return ability_id != "" and not active and cooldown_left <= 0.0


func activate() -> bool:
	if not is_ready():
		return false
	active = true
	time_left = float(DURATION.get(ability_id, 5.0))
	_apply_start()
	AudioManager.play_sfx("ability")
	_emit()
	return true


func _physics_process(delta: float) -> void:
	if cooldown_left > 0.0:
		cooldown_left = maxf(0.0, cooldown_left - delta)
	if active:
		time_left -= delta
		if time_left <= 0.0:
			_end()
			return
	_emit()


## Push the current ability state to the HUD (e.g. right after binding).
func emit_state() -> void:
	_emit()


func _end() -> void:
	active = false
	time_left = 0.0
	cooldown_left = float(COOLDOWN.get(ability_id, 4.0))
	_apply_end()
	_emit()


func _apply_start() -> void:
	match ability_id:
		"gravity_reverse":
			if fox != null:
				fox.set_gravity_dir(-1)
		"time_freeze":
			for n in _time_nodes():
				if n.has_method("set_frozen"):
					n.set_frozen(true)
		"time_slow":
			for n in _time_nodes():
				if n.has_method("set_time_scale"):
					n.set_time_scale(0.3)
				if n.has_method("set_reversed"):
					n.set_reversed(true)


func _apply_end() -> void:
	match ability_id:
		"gravity_reverse":
			if fox != null:
				fox.set_gravity_dir(1)
		"time_freeze":
			for n in _time_nodes():
				if n.has_method("set_frozen"):
					n.set_frozen(false)
		"time_slow":
			for n in _time_nodes():
				if n.has_method("set_time_scale"):
					n.set_time_scale(1.0)
				if n.has_method("set_reversed"):
					n.set_reversed(false)


func _time_nodes() -> Array:
	return get_tree().get_nodes_in_group("time_affected")


func _emit() -> void:
	var ready_now := is_ready()
	state_changed.emit(display_name(), active, time_left, cooldown_left, ready_now)
