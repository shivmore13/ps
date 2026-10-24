extends CanvasLayer
## Victory / ending sequence. Shows run statistics and offers a replay.

func _ready() -> void:
	layer = 26
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.03, 0.12, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(640, 460)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var title := Label.new()
	title.text = "VICTORY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 60)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	title.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.0))
	title.add_theme_constant_override("outline_size", 8)
	box.add_child(title)

	var sub := Label.new()
	sub.text = "The four realms are free. The white fox prevails."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 22)
	box.add_child(sub)

	var stats := Label.new()
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 24)
	stats.text = "\nCherries collected:  %d\nGuardians defeated:  %d\nFinal score:  %d\n" % [
		GameState.total_cherries, GameState.bosses_defeated_count(), GameState.score]
	box.add_child(stats)

	var fox := AnimatedSprite2D.new()
	fox.sprite_frames = load("res://Assets/sprites/fox/fox_frames.tres")
	fox.animation = "victory"
	fox.scale = Vector2(3, 3)
	fox.play()
	box.add_child(fox)

	box.add_child(_button("Play Again", func() -> void:
		GameState.reset_run()
		GameState.current_level = 0
		get_tree().paused = false
		AudioManager.stop_music()
		get_tree().change_scene_to_file("res://scenes/levels/level.tscn")))
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
