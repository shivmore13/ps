extends Area2D
## Moving damaging zone (sweeping beam / thorn / energy barrier).
## Time-affected: freezing or slowing it opens the corridor it guards.

var clock := MoverClock.new()
var offset := Vector2.ZERO
var cycle := 2.0
var _base := Vector2.ZERO
var _t := 0.0

@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var visual: ColorRect = $Visual


func _ready() -> void:
	add_to_group("time_affected")
	add_to_group("hazard")
	body_entered.connect(_on_body_entered)
	_base = position
	_t = randf() * cycle


func configure(size: Vector2, color: Color, off: Vector2, cycle_time: float) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	collider.shape = shape
	visual.size = size
	visual.position = -size * 0.5
	visual.color = color
	offset = off
	cycle = maxf(0.2, cycle_time)


func set_frozen(v: bool) -> void:
	clock.frozen = v


func set_time_scale(v: float) -> void:
	clock.time_scale = v


func set_reversed(v: bool) -> void:
	clock.reversed = v


func _physics_process(delta: float) -> void:
	_t += clock.step(delta)
	var f := (1.0 - cos(_t / cycle * TAU)) * 0.5
	position = _base + offset * f


func _on_body_entered(body: Node) -> void:
	if body is Fox:
		(body as Fox).hazard_hit(1)
