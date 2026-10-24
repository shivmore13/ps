extends AnimatableBody2D
class_name TimePlatform
## One reusable platform covering every platformer variant:
## solid, moving (time-affected), crumbling, disappearing and hidden.

enum Kind { SOLID, MOVING, CRUMBLING, DISAPPEARING, HIDDEN }

var kind: Kind = Kind.SOLID
var move_offset := Vector2.ZERO
var move_cycle := 3.0
var crumble_delay := 0.7
var respawn_delay := 3.0
var vanish_period := 2.5
var vanish_phase := 0.0
var affected := false
var clock := MoverClock.new()

var body_size := Vector2(150, 36)
var _base := Vector2.ZERO
var _t := 0.0
var _timer := 0.0
var _crumbling := false
var _gone := false
var _hidden_active := false
var _pending_off := false

@onready var collider: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_base = position
	_t = vanish_phase * vanish_period
	var shape := RectangleShape2D.new()
	shape.size = body_size
	collider.shape = shape
	if affected:
		add_to_group("time_affected")
	if kind == Kind.HIDDEN:
		add_to_group("hidden_platform")
		set_active(false)
	elif kind == Kind.DISAPPEARING:
		_apply_vanish()


func configure(k: Kind, size: Vector2) -> void:
	kind = k
	body_size = size


func _physics_process(delta: float) -> void:
	match kind:
		Kind.MOVING:
			_t += clock.step(delta)
			var f := (1.0 - cos(_t / maxf(0.2, move_cycle) * TAU)) * 0.5
			position = _base + move_offset * f
		Kind.CRUMBLING:
			_process_crumble(delta)
		Kind.DISAPPEARING:
			_t += delta
			_apply_vanish()
		Kind.HIDDEN:
			if _pending_off and not _player_standing():
				set_active(false)
				_pending_off = false


func _process_crumble(delta: float) -> void:
	if _gone:
		_timer -= delta
		if _timer <= 0.0:
			_restore()
		return
	if _player_standing():
		_crumbling = true
	if _crumbling:
		_timer -= delta
		# shake as a warning
		collider.position.x = sin(_timer * 60.0) * 2.0
		modulate = Color(1.0, 0.8, 0.7)
		if _timer <= 0.0:
			_collapse()


func _collapse() -> void:
	_gone = true
	_crumbling = false
	collision_layer = 0
	visible = false
	collider.position.x = 0.0
	_timer = respawn_delay


func _restore() -> void:
	_gone = false
	collision_layer = _layer_for_kind()
	visible = true
	modulate = Color.WHITE
	_timer = 0.0


func _apply_vanish() -> void:
	var phase := fmod(_t / maxf(0.2, vanish_period), 1.0)
	var on := phase < 0.62
	_set_solid(on)


func _set_solid(on: bool) -> void:
	collision_layer = _layer_for_kind() if on else 0
	visible = on
	modulate = Color.WHITE if on else modulate


func _layer_for_kind() -> int:
	return 256 if kind == Kind.HIDDEN else 1


func set_active(on: bool) -> void:
	_hidden_active = on
	collision_layer = 256 if on else 0
	visible = on
	modulate = Color(0.75, 0.65, 1.0, 0.92) if on else Color.WHITE
	if on:
		FX.ring(get_parent(), global_position, Color(0.8, 0.6, 1.0), 26.0)


func request_deactivate() -> void:
	_pending_off = true


func _player_standing() -> bool:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return false
	var p := players[0]
	if not (p is Fox):
		return false
	if not (p as Fox).is_on_floor():
		return false
	var top := global_position.y - body_size.y * 0.5
	return absf(p.global_position.y - top) < 50.0 and absf(p.global_position.x - global_position.x) < body_size.x * 0.5 + 26.0
