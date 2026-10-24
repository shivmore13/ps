extends StaticBody2D
## Cherry seal that blocks the way to the gun until enough cherries are collected.

signal opened

var _open := false

@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var visual: ColorRect = $Visual


func configure(size: Vector2, color: Color) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	collider.shape = shape
	visual.size = size
	visual.position = -size * 0.5
	visual.color = color


func is_open() -> bool:
	return _open


func open() -> void:
	if _open:
		return
	_open = true
	AudioManager.play_sfx("checkpoint")
	FX.ring(get_parent(), global_position, Color(1.0, 0.9, 0.4), 60.0)
	var t := create_tween()
	t.tween_property(visual, "modulate:a", 0.0, 0.5)
	t.tween_callback(func() -> void:
		collision_layer = 0
		visible = false)
	opened.emit()
