extends Area2D
## Level exit portal. Becomes active once the realm's boss is defeated;
## press Interact (E) while standing inside to travel onward.

signal entered

var active := false
var _player_inside := false
var _t := 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("portal")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	set_active(false)


func set_active(v: bool) -> void:
	active = v
	modulate = Color(1, 1, 1, 1) if v else Color(0.55, 0.55, 0.65, 0.75)


func _process(delta: float) -> void:
	_t += delta
	if active:
		var s := 1.0 + sin(_t * 3.0) * 0.06
		sprite.scale = Vector2(s, s)
		rotation = sin(_t * 0.8) * 0.04
	else:
		sprite.scale = Vector2.ONE
	if active and _player_inside and Input.is_action_just_pressed("interact"):
		AudioManager.play_sfx("portal", randf_range(0.95, 1.1))
		entered.emit()


func _on_body_entered(body: Node) -> void:
	if body is Fox:
		_player_inside = true


func _on_body_exited(body: Node) -> void:
	if body is Fox:
		_player_inside = false
