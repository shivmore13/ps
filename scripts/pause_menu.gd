extends CanvasLayer
class_name PauseMenu
## Pause overlay: resume, restart checkpoint, volume sliders, main menu.

var root: Control
var music_slider: HSlider
var sfx_slider: HSlider


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


func toggle() -> void:
	visible = not visible
	get_tree().paused = visible


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()


func _build() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(420, 380)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	box.add_child(title)

	box.add_child(_button("Resume", _resume))
	box.add_child(_button("Restart Level", _restart))
	box.add_child(_button("Restart Campaign", _confirm_restart_campaign))
	box.add_child(_button("Main Menu", _main_menu))

	var ml := Label.new()
	ml.text = "Music"
	box.add_child(ml)
	music_slider = _slider(AudioManager.music_volume, func(v: float) -> void: AudioManager.set_music_volume(v))
	box.add_child(music_slider)
	var sl := Label.new()
	sl.text = "Sound Effects"
	box.add_child(sl)
	sfx_slider = _slider(AudioManager.sfx_volume, func(v: float) -> void: AudioManager.set_sfx_volume(v))
	box.add_child(sfx_slider)


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb)
	return b


func _slider(value: float, cb: Callable) -> HSlider:
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(0, 28)
	s.value_changed.connect(cb)
	return s


func _resume() -> void:
	visible = false
	get_tree().paused = false


func _restart() -> void:
	get_tree().paused = false
	AudioManager.stop_music()
	get_tree().reload_current_scene()


func _main_menu() -> void:
	get_tree().paused = false
	AudioManager.stop_music()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _confirm_restart_campaign() -> void:
	var d := ConfirmationDialog.new()
	d.title = "Restart Campaign"
	d.dialog_text = "Restart the whole campaign from Level One?\n\nAll progress will be lost."
	add_child(d)
	d.confirmed.connect(func() -> void:
		get_tree().paused = false
		GameState.delete_save()
		GameState.reset_run()
		GameState.current_level = 0
		AudioManager.stop_music()
		get_tree().change_scene_to_file("res://scenes/levels/level.tscn"))
	d.popup_centered()
