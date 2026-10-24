extends Area2D
class_name Cherry
## Edible cherry pickup. Bobs in place, plays a sparkle on collection.

var level_index := 0
var _t := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("cherry")
	body_entered.connect(_on_body_entered)
	if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation("spin"):
		sprite.play("spin")
	_t = randf() * TAU


func _process(delta: float) -> void:
	_t += delta
	sprite.position.y = -6.0 + sin(_t * 2.6) * 5.0


func _on_body_entered(body: Node) -> void:
	if body is Fox:
		GameState.collect_cherry(level_index)
		AudioManager.play_sfx("cherry", randf_range(0.95, 1.15))
		FX.burst(get_parent(), global_position, Color(1.0, 0.3, 0.45), 12, 190.0)
		queue_free()
