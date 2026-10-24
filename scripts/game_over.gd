extends CanvasLayer
## Game-over screen shown when the fox runs out of hearts.

var _title: Label
var _info: Label


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


func setup(_level_index: int) -> void:
	visible = true
	_title.text = "YOU FELL"
	_info.text = "Cherries collected so far:  %d\n\nThe realm claims another hero.\nRetry the level, or return to the main menu." % GameState.total_cherries


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.0, 0.0, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(520, 320)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	_title = Label.new()
	_title.text = "YOU FELL"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 48)
	_title.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	box.add_child(_title)

	_info = Label.new()
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.add_theme_font_size_override("font_size", 20)
	box.add_child(_info)

	box.add_child(_button("Retry Level", func() -> void:
		get_tree().paused = false
		AudioManager.stop_music()
		get_tree().reload_current_scene()))
	box.add_child(_button("Main Menu", func() -> void:
		get_tree().paused = false
		AudioManager.stop_music()
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")))


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(360, 46)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb)
	return b
