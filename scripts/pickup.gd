extends Area2D
## Small pickup: restores a heart or grants ammo.
## `kind` is set by the level builder to "heart" or "ammo".

var kind := "heart"
var _t := 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("pickup")
	body_entered.connect(_on_body_entered)
	_t = randf() * TAU
	if sprite != null:
		var tex_path := "res://Assets/generated/ui_heart.png" if kind == "heart" else "res://Assets/generated/ui_bullet.png"
		sprite.texture = load(tex_path)


func _process(delta: float) -> void:
	_t += delta
	sprite.position.y = -1.0 + sin(_t * 3.0) * 4.0


func _on_body_entered(body: Node) -> void:
	if not (body is Fox):
		return
	if kind == "heart":
		if GameState.hearts >= GameState.max_hearts:
			return
		GameState.heal(1)
		AudioManager.play_sfx("cherry", 0.8)
		FX.burst(get_parent(), global_position, Color(1.0, 0.4, 0.5), 10, 160.0)
	else:
		GameState.add_ammo(6)
		AudioManager.play_sfx("cherry", 1.2)
		FX.burst(get_parent(), global_position, Color(0.6, 0.9, 1.0), 10, 160.0)
	queue_free()
