extends Area2D
class_name KeyPickup
## A dimensional key lying in the world (the Void Key, found on an optional
## route). Grants the key to the campaign when the King touches it.

var key_id := "void"
var _t := 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("key_pickup")
	body_entered.connect(_on_body_entered)
	if sprite != null:
		sprite.texture = FX.load_tex("res://Assets/generated/prop_key.png")
		sprite.modulate = Dimensions.key_color(key_id)
	_t = randf() * TAU


func _process(delta: float) -> void:
	_t += delta
	if sprite != null:
		sprite.position.y = sin(_t * 2.2) * 6.0
		sprite.rotation = sin(_t * 1.5) * 0.15


func _on_body_entered(body: Node) -> void:
	if body is Fox:
		GameState.collect_key(key_id)
		AudioManager.play_sfx("key")
		FX.ring(get_parent(), global_position, Dimensions.key_color(key_id), 60.0)
		queue_free()
