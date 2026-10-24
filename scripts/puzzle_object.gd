extends Area2D
class_name PuzzleObject
## One interactive puzzle element (Ember Seal lever, tide valve, pedestal,
## living seed-stone). Reports interaction to the PuzzleManager.

signal interacted(obj: PuzzleObject)

enum Kind { LEVER, VALVE, PEDESTAL, CRYSTAL }

var kind: Kind = Kind.LEVER
var pid := 0
var symbol := ""
var tint := Color.WHITE
var tex_path := ""
var states := 3
var state := 0
var active := false
var required_key := ""

var _player_inside := false
var _t := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var symbol_label: Label = $Symbol
@onready var collider: CollisionShape2D = $CollisionShape2D


func configure(k: Kind, id: int, tex: String, sym: String, color: Color, nstates: int, key: String) -> void:
	kind = k
	pid = id
	tex_path = tex
	symbol = sym
	tint = color
	states = maxi(1, nstates)
	required_key = key


func _ready() -> void:
	add_to_group("puzzle_object")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if tex_path != "":
		sprite.texture = FX.load_tex(tex_path)
	symbol_label.text = symbol
	_t = randf() * TAU
	refresh_state()


func _process(delta: float) -> void:
	_t += delta
	if active:
		sprite.position.y = sin(_t * 3.0) * 3.0
		symbol_label.position.y = -34.0 + sprite.position.y


func _unhandled_input(event: InputEvent) -> void:
	if _player_inside and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interacted.emit(self)


func refresh_state() -> void:
	if sprite == null:
		return
	if kind == Kind.VALVE:
		sprite.rotation = float(state) * TAU / float(states)
	sprite.modulate = tint if active else tint.darkened(0.25)
	if active:
		sprite.modulate = tint.lightened(0.25)


func set_active(v: bool) -> void:
	active = v
	refresh_state()
	if v:
		FX.ring(get_parent(), global_position, tint, 34.0)


func _on_body_entered(body: Node) -> void:
	if body is Fox:
		_player_inside = true


func _on_body_exited(body: Node) -> void:
	if body is Fox:
		_player_inside = false


func is_player_near() -> bool:
	return _player_inside
