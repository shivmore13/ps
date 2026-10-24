extends Area2D
## Player projectile fired from the gun. Dies on walls, damages bosses.

const SPEED := 950.0
const LIFE := 1.3

var dir := Vector2.RIGHT
var _life := LIFE


func _ready() -> void:
	add_to_group("projectile")
	body_entered.connect(_on_body_entered)


func setup(d: Vector2) -> void:
	dir = d.normalized()
	rotation = dir.angle()


func _physics_process(delta: float) -> void:
	position += dir * SPEED * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("boss") and body.has_method("take_damage"):
		body.take_damage(1)
		FX.burst(get_parent(), global_position, Color(0.7, 0.95, 1.0), 8, 150.0)
		AudioManager.play_sfx("enemy_hit", randf_range(0.9, 1.1))
		queue_free()
	elif body is StaticBody2D:
		FX.burst(get_parent(), global_position, Color(0.9, 0.95, 1.0), 5, 90.0)
		queue_free()
