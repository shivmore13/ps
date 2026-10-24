extends CanvasLayer
class_name Cutscene
## Reusable cinematic player. Given a list of "shots" (see StoryData) it shows
## backgrounds, character sprites and a dialogue box, advancing on interact /
## jump / click, with a Skip button. Emits `finished` when done.

signal finished

const MUSIC_DEFAULT := "story"

var shots: Array = []
var index := -1
var playing := false

var _on_done: Callable = Callable()
var _sprites: Node2D
var _bg: TextureRect
var _dim: ColorRect
var _box: PanelContainer
var _speaker: Label
var _text: Label
var _title: Label
var _sub: Label
var _hint: Label


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


func play(list: Array, on_done: Callable = Callable(), music: String = MUSIC_DEFAULT) -> void:
	shots = list
	index = -1
	_on_done = on_done
	playing = true
	visible = true
	get_tree().paused = true
	AudioManager.play_music(music)
	_next()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var black := ColorRect.new()
	black.color = Color(0.03, 0.02, 0.06, 1.0)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(black)

	_bg = TextureRect.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	root.add_child(_bg)

	_dim = ColorRect.new()
	_dim.color = Color(0.02, 0.02, 0.08, 0.35)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(_dim)

	_sprites = Node2D.new()
	root.add_child(_sprites)

	_title = Label.new()
	_title.set_anchors_preset(Control.PRESET_CENTER)
	_title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_title.grow_vertical = Control.GROW_DIRECTION_BOTH
	_title.position = Vector2(0, -60)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 84)
	_title.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
	_title.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.3))
	_title.add_theme_constant_override("outline_size", 12)
	root.add_child(_title)

	_sub = Label.new()
	_sub.set_anchors_preset(Control.PRESET_CENTER)
	_sub.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_sub.grow_vertical = Control.GROW_DIRECTION_BOTH
	_sub.position = Vector2(0, 20)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.add_theme_font_size_override("font_size", 30)
	_sub.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	_sub.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_sub.add_theme_constant_override("outline_size", 6)
	root.add_child(_sub)

	_box = PanelContainer.new()
	_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_box.offset_left = 120.0
	_box.offset_right = -120.0
	_box.offset_top = -220.0
	_box.offset_bottom = -40.0
	root.add_child(_box)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	_box.add_child(vb)
	_speaker = Label.new()
	_speaker.add_theme_font_size_override("font_size", 24)
	_speaker.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	vb.add_child(_speaker)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("font_size", 22)
	_text.add_theme_color_override("font_color", Color(0.96, 0.96, 1.0))
	vb.add_child(_text)
	_hint = Label.new()
	_hint.text = "Press  E  /  Space  /  Click  to continue"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_font_size_override("font_size", 16)
	_hint.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	vb.add_child(_hint)

	var skip := Button.new()
	skip.text = "Skip  \u25B6\u25B6"
	skip.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip.offset_left = -170.0
	skip.offset_top = 20.0
	skip.offset_right = -20.0
	skip.offset_bottom = 62.0
	skip.add_theme_font_size_override("font_size", 20)
	skip.pressed.connect(_skip)
	root.add_child(skip)


func _next() -> void:
	if not playing:
		return
	index += 1
	if index >= shots.size():
		_end()
		return
	_render(shots[index])


func _render(shot: Dictionary) -> void:
	var bg_path := String(shot.get("bg", ""))
	if bg_path != "":
		_bg.texture = FX.load_tex(bg_path)
		_bg.visible = true
		_dim.visible = true
	else:
		_bg.visible = false
		_dim.visible = false

	for c in _sprites.get_children():
		c.queue_free()
	for s in shot.get("sprites", []):
		var spr := Sprite2D.new()
		spr.texture = FX.load_tex(String(s.tex))
		spr.position = Vector2(float(s.get("x", 640.0)), float(s.get("y", 400.0)))
		var sc := float(s.get("scale", 2.0))
		spr.scale = Vector2(sc, sc)
		spr.flip_h = bool(s.get("flip", false))
		_sprites.add_child(spr)
		var base_y := spr.position.y
		var tw := spr.create_tween().set_loops()
		tw.tween_property(spr, "position:y", base_y + 7.0, 1.3).set_trans(Tween.TRANS_SINE)
		tw.tween_property(spr, "position:y", base_y, 1.3).set_trans(Tween.TRANS_SINE)

	if shot.has("title"):
		_title.text = String(shot.title)
		_sub.text = String(shot.get("sub", ""))
		_title.visible = true
		_sub.visible = true
		_box.visible = false
		_hint.visible = false
	else:
		_title.visible = false
		_sub.visible = false
		_box.visible = true
		_hint.visible = true
		_speaker.text = String(shot.get("speaker", ""))
		_text.text = String(shot.get("text", ""))

	var tw2 := create_tween()
	tw2.tween_property(_dim, "modulate:a", 0.6, 0.12)
	tw2.tween_property(_dim, "modulate:a", 1.0, 0.18)


func _unhandled_input(event: InputEvent) -> void:
	if not playing:
		return
	var advance := event.is_action_pressed("interact") or event.is_action_pressed("jump")
	if event is InputEventMouseButton and event.pressed:
		advance = true
	if advance:
		get_viewport().set_input_as_handled()
		_next()


func _skip() -> void:
	if not playing:
		return
	_end()


func _end() -> void:
	playing = false
	visible = false
	get_tree().paused = false
	finished.emit()
	if _on_done.is_valid():
		_on_done.call()
	queue_free()
