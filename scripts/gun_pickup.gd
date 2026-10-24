extends Area2D
## The gun pickup. Touching it unlocks shooting for the current realm.

var _t := 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("gun_pickup")
	body_entered.connect(_on_body_entered)
	_t = randf() * TAU


func _process(delta: float) -> void:
	_t += delta
	sprite.position.y = -2.0 + sin(_t * 2.2) * 6.0
	sprite.rotation = sin(_t * 1.4) * 0.12


func _on_body_entered(body: Node) -> void:
	if body is Fox and not GameState.gun_unlocked:
		GameState.collect_gun(20)
		AudioManager.play_sfx("gun_pickup")
		FX.ring(get_parent(), global_position, Color(0.5, 0.9, 1.0), 50.0)
		queue_free()
