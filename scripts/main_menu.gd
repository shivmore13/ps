extends Control
## Main menu: Play / Continue, Level Select, Settings and Quit,
## with the game's control guide.

const LEVEL_SCENE := "res://scenes/levels/level.tscn"
const CUTSCENE_SCENE := "res://scenes/cinematics/cutscene.tscn"
const TITLE_BG := "res://Assets/generated/title_bg.png"
const FOX_FRAMES := "res://Assets/sprites/king/king_frames.tres"

var main_box: VBoxContainer
var level_box: VBoxContainer
var settings_box: VBoxContainer
var controls_box: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	AudioManager.play_music("void")
	_build_background()
	_build_main()
	_build_level_select()
	_build_settings()
	_build_controls()


func _build_background() -> void:
	var bg := TextureRect.new()
	bg.texture = load(TITLE_BG)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.06, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var fox := AnimatedSprite2D.new()
	fox.sprite_frames = load(FOX_FRAMES)
	fox.scale = Vector2(3, 3)
	fox.position = Vector2(180, 560)
	fox.animation = "idle"
	fox.play()
	add_child(fox)
	var queen := Sprite2D.new()
	queen.texture = FX.load_tex("res://Assets/generated/queen_idle.png")
	queen.scale = Vector2(2.6, 2.6)
	queen.position = Vector2(1100, 545)
	add_child(queen)


func _build_main() -> void:
	main_box = VBoxContainer.new()
	main_box.set_anchors_preset(Control.PRESET_CENTER)
	main_box.position = Vector2(0, 40)
	main_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	main_box.grow_vertical = Control.GROW_DIRECTION_BOTH
	main_box.add_theme_constant_override("separation", 12)
	add_child(main_box)

	var title := Label.new()
	title.text = "ORPHOX"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.35))
	title.add_theme_constant_override("outline_size", 10)
	main_box.add_child(title)

	var sub := Label.new()
	sub.text = "The Kingdom Beyond Dimensions"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 28)
	sub.add_theme_color_override("font_color", Color(0.8, 0.85, 1.0))
	sub.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	sub.add_theme_constant_override("outline_size", 6)
	main_box.add_child(sub)

	main_box.add_child(_spacer(10))
	if GameState.has_save():
		main_box.add_child(_button("Continue", _continue_game))
	main_box.add_child(_button("New Game", _new_game))
	main_box.add_child(_button("Level Select", _show_level_select))
	main_box.add_child(_button("Settings", _show_settings))
	main_box.add_child(_button("Controls", _show_controls))
	main_box.add_child(_button("Restart Campaign", _confirm_restart_campaign))
	main_box.add_child(_button("Quit", func() -> void: get_tree().quit()))


func _build_level_select() -> void:
	level_box = VBoxContainer.new()
	level_box.set_anchors_preset(Control.PRESET_CENTER)
	level_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	level_box.grow_vertical = Control.GROW_DIRECTION_BOTH
	level_box.add_theme_constant_override("separation", 12)
	add_child(level_box)
	var t := _heading("LEVEL SELECT")
	level_box.add_child(t)
	for i in Levels.LEVELS.size():
		var idx := i
		var unlocked := i < GameState.levels_unlocked
		var b := _button("%d. %s" % [idx + 1, Levels.realm_name(idx)], func() -> void: _start_level(idx))
		b.disabled = not unlocked
		if not unlocked:
			b.text += "  (locked)"
		level_box.add_child(b)
	level_box.add_child(_button("Back", func() -> void: _show_menu_only()))
	level_box.visible = false


func _build_settings() -> void:
	settings_box = VBoxContainer.new()
	settings_box.set_anchors_preset(Control.PRESET_CENTER)
	settings_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	settings_box.grow_vertical = Control.GROW_DIRECTION_BOTH
	settings_box.add_theme_constant_override("separation", 14)
	add_child(settings_box)
	settings_box.add_child(_heading("SETTINGS"))

	var ml := Label.new()
	ml.text = "Music Volume"
	ml.add_theme_font_size_override("font_size", 22)
	settings_box.add_child(ml)
	settings_box.add_child(_slider(AudioManager.music_volume, func(v: float) -> void: AudioManager.set_music_volume(v)))

	var sl := Label.new()
	sl.text = "Sound Effects Volume"
	sl.add_theme_font_size_override("font_size", 22)
	settings_box.add_child(sl)
	settings_box.add_child(_slider(AudioManager.sfx_volume, func(v: float) -> void: AudioManager.set_sfx_volume(v)))

	var fb := _button("Toggle Fullscreen", func() -> void:
		var mode := DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN))
	settings_box.add_child(fb)
	settings_box.add_child(_button("Back", func() -> void: _show_menu_only()))
	settings_box.visible = false


func _build_controls() -> void:
	controls_box = VBoxContainer.new()
	controls_box.set_anchors_preset(Control.PRESET_CENTER)
	controls_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	controls_box.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(controls_box)
	controls_box.add_child(_heading("CONTROLS"))
	var l := Label.new()
	l.text = "A / D or \u2190 \u2192   Move\nSPACE   Jump\nE   Interact / enter portal\nF   Anti-physics ability\nLeft Mouse   Shoot (after collecting the gun)\nR   Restart level\nEsc   Pause\n\nCollect cherries to break each realm's seal,\nclaim the gun, then defeat the guardian beast."
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	controls_box.add_child(l)
	controls_box.add_child(_button("Back", func() -> void: _show_menu_only()))
	controls_box.visible = false


## ---- helpers --------------------------------------------------------------

func _heading(text: String) -> Label:
	var t := Label.new()
	t.text = text
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 34)
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	t.add_theme_constant_override("outline_size", 6)
	return t


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(360, 46)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb)
	return b


func _slider(value: float, cb: Callable) -> HSlider:
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(360, 28)
	s.value_changed.connect(cb)
	return s


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _show_menu_only() -> void:
	main_box.visible = true
	level_box.visible = false
	settings_box.visible = false
	controls_box.visible = false


func _show_level_select() -> void:
	main_box.visible = false
	level_box.visible = true
	settings_box.visible = false
	controls_box.visible = false


func _show_settings() -> void:
	main_box.visible = false
	level_box.visible = false
	settings_box.visible = true
	controls_box.visible = false


func _show_controls() -> void:
	main_box.visible = false
	level_box.visible = false
	settings_box.visible = false
	controls_box.visible = true


func _new_game() -> void:
	GameState.reset_run()
	GameState.current_level = 0
	_play_intro_then_start()


func _play_intro_then_start() -> void:
	var cs: Cutscene = load(CUTSCENE_SCENE).instantiate()
	add_child(cs)
	cs.play(StoryData.intro(), func() -> void: _start_level(0), "story")


func _confirm_restart_campaign() -> void:
	var d := ConfirmationDialog.new()
	d.title = "Restart Campaign"
	d.dialog_text = "Restart the whole campaign from Level One?\n\nAll progress (cherries, dimensional keys and defeated guardians) will be lost."
	add_child(d)
	d.confirmed.connect(func() -> void:
		GameState.delete_save()
		GameState.reset_run()
		GameState.current_level = 0
		_play_intro_then_start())
	d.popup_centered()


func _continue_game() -> void:
	GameState.load_game()
	GameState.current_level = GameState.checkpoint_level
	_start_level(GameState.current_level)


func _start_level(index: int) -> void:
	GameState.current_level = clampi(index, 0, Levels.LEVELS.size() - 1)
	AudioManager.stop_music()
	get_tree().change_scene_to_file(LEVEL_SCENE)
