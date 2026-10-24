extends CanvasLayer
class_name Ending
## The mandatory finale: the ending cinematic (Varkhos falls, the cage breaks,
## the royal reunion) followed by the final victory screen with run statistics.

const CUTSCENE_SCENE := "res://scenes/cinematics/cutscene.tscn"
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const LEVEL_SCENE := "res://scenes/levels/level.tscn"

var _panel: Control
var _firework_timer: Timer


func _ready() -> void:
	layer = 44
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_panel()
	_panel.visible = false
	var cs: Cutscene = load(CUTSCENE_SCENE).instantiate()
	add_child(cs)
	cs.play(StoryData.ending(), _show_final, "victory")


func _show_final() -> void:
	_panel.visible = true
	AudioManager.play_sfx("reunion")
	AudioManager.play_music("victory", true)
	_firework_timer = Timer.new()
	_firework_timer.wait_time = 0.55
	_firework_timer.autostart = true
	_firework_timer.timeout.connect(_firework)
	add_child(_firework_timer)


func _firework() -> void:
	var colors := [Color(1.0, 0.8, 0.3), Color(1.0, 0.4, 0.6), Color(0.5, 0.9, 1.0), Color(0.7, 1.0, 0.5)]
	FX.ring(_panel, Vector2(randf_range(120.0, 1160.0), randf_range(80.0, 420.0)), colors.pick_random(), 70.0)
	AudioManager.play_sfx("firework", randf_range(0.9, 1.2))


func _build_panel() -> void:
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.12, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(dim)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 12)
	_panel.add_child(box)

	var title := Label.new()
	title.text = "THE KINGDOM IS WHOLE AGAIN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6))
	title.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.0))
	title.add_theme_constant_override("outline_size", 10)
	box.add_child(title)

	var sub := Label.new()
	sub.text = "Four realms conquered.  One queen rescued.  A kingdom reborn."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 22)
	box.add_child(sub)

	var stats := Label.new()
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 22)
	var mins := int(GameState.elapsed_seconds()) / 60
	var secs := int(GameState.elapsed_seconds()) % 60
	stats.text = "\nCherries collected:  %d\nGuardians defeated:  %d / 4\nDimensional keys:  %d / 4\nCompletion time:  %02d:%02d\nFinal score:  %d\nAchievements:  %s" % [
		GameState.total_cherries, GameState.bosses_defeated_count(),
		GameState.key_count(), mins, secs, GameState.score, _achievements()]
	box.add_child(stats)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	row.add_child(_button("Play Again", _play_again))
	row.add_child(_button("Main Menu", _main_menu))
	row.add_child(_button("Quit Game", func() -> void: get_tree().quit()))


func _achievements() -> String:
	var got: Array = []
	if GameState.total_cherries >= 40:
		got.append("Cherry Collector")
	if GameState.bosses_defeated_count() >= 4:
		got.append("Guardian Slayer")
	if GameState.key_count() >= 4:
		got.append("Keybearer")
	if got.is_empty():
		got.append("Survivor")
	return ", ".join(got)


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(200, 50)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb)
	return b


func _play_again() -> void:
	GameState.reset_run()
	GameState.current_level = 0
	get_tree().paused = false
	AudioManager.stop_music()
	get_tree().change_scene_to_file(LEVEL_SCENE)


func _main_menu() -> void:
	get_tree().paused = false
	AudioManager.stop_music()
	get_tree().change_scene_to_file(MENU_SCENE)
