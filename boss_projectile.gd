extends Area2D
## Boss projectile. Affected by time abilities, passes over terrain.

var clock := MoverClock.new()
var dir := Vector2.RIGHT
var speed := 260.0
var proj_color := Color(1.0, 0.5, 0.1)
var _life := 5.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("time_affected")
	body_entered.connect(_on_body_entered)
	if sprite != null:
		sprite.modulate = proj_color


func setup(d: Vector2, spd: float = 260.0) -> void:
	dir = d.normalized()
	speed = spd
	rotation = dir.angle()
	if sprite != null:
		sprite.modulate = proj_color


func set_frozen(v: bool) -> void:
	clock.frozen = v


func set_time_scale(v: float) -> void:
	clock.time_scale = v


func set_reversed(v: bool) -> void:
	clock.reversed = v


func _physics_process(delta: float) -> void:
	var d := clock.step(delta)
	if d != 0.0:
		position += dir * speed * d
		rotation += 2.0 * d
	if not clock.frozen:
		_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body is Fox:
		body.take_damage(1, global_position)
		FX.burst(get_parent(), global_position, Color(1.0, 0.6, 0.4), 8, 130.0)
		queue_free()
