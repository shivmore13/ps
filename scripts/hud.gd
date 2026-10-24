extends CanvasLayer
class_name HUD
## In-game heads-up display: hearts, cherries, ammo, level name, ability status,
## boss health bar, contextual prompts and toasts.

const HEART_TEX := "res://Assets/generated/ui_heart.png"
const BULLET_TEX := "res://Assets/generated/ui_bullet.png"
const KEY_TEX := "res://Assets/generated/prop_key.png"
const CHERRY_TEX := "res://Sunny-land-files/Assets/Misc/Sunnyland items/Sprites/cherry/cherry-1.png"
const PAUSE_SCENE := "res://scenes/ui/pause_menu.tscn"

var hearts_box: HBoxContainer
var cherry_label: Label
var ammo_label: Label
var level_label: Label
var ability_label: Label
var ability_bar: ProgressBar
var puzzle_label: Label
var keys_box: HBoxContainer
var prompt_label: Label
var toast_label: Label
var controls_panel: PanelContainer
var boss_panel: PanelContainer
var boss_name_label: Label
var boss_bar: ProgressBar

var _fox: Fox
var _boss: Boss
var _toast_timer := 0.0
var _controls_timer := 0.0


func _ready() -> void:
	layer = 5
	_build()
	GameState.hearts_changed.connect(_on_hearts_changed)
	GameState.cherries_changed.connect(func(_t: int) -> void: _refresh_cherries())
	GameState.ammo_changed.connect(func(_a: int) -> void: _refresh_ammo())
	GameState.gun_changed.connect(func(_u: bool) -> void: _refresh_ammo())
	GameState.keys_changed.connect(_on_keys_changed)
	GameState.puzzle_changed.connect(_on_puzzle_changed)
	_refresh_cherries()
	_refresh_ammo()
	_on_hearts_changed(GameState.hearts, GameState.max_hearts)
	_on_keys_changed(GameState.keys)


func bind(fox: Fox, boss: Boss, level_index: int, boss_name: String) -> void:
	_fox = fox
	_boss = boss
	if fox != null:
		fox.ability_manager.state_changed.connect(_on_ability_changed)
		fox.ability_manager.emit_state()
	level_label.text = "Level %d  \u2022  %s" % [level_index + 1, Levels.realm_name(level_index)]
	boss_name_label.text = boss_name


func add_pause_menu() -> void:
	var pm: Node = load(PAUSE_SCENE).instantiate()
	pm.name = "PauseMenu"
	add_child(pm)


func request_controls_guide(enabled: bool) -> void:
	if enabled:
		controls_panel.visible = true
		_controls_timer = 9.0


## ---- Build ----------------------------------------------------------------

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	level_label = _make_label(root, Vector2(24, 16), 22)
	level_label.text = "Level 1"

	hearts_box = HBoxContainer.new()
	hearts_box.position = Vector2(24, 52)
	hearts_box.add_theme_constant_override("separation", 6)
	root.add_child(hearts_box)

	cherry_label = _make_label(root, Vector2(24, 96), 22)
	cherry_label.text = "0 cherries"

	ammo_label = _make_label(root, Vector2(24, 130), 22)
	ammo_label.text = "No gun"

	ability_label = _make_label(root, Vector2(24, 176), 20)
	ability_bar = ProgressBar.new()
	ability_bar.position = Vector2(24, 206)
	ability_bar.custom_minimum_size = Vector2(240, 14)
	ability_bar.size = Vector2(240, 14)
	ability_bar.show_percentage = false
	ability_bar.max_value = 1.0
	ability_bar.value = 1.0
	root.add_child(ability_bar)

	puzzle_label = _make_label(root, Vector2(24, 232), 18)
	puzzle_label.text = ""

	keys_box = HBoxContainer.new()
	keys_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	keys_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	keys_box.position = Vector2(-236, 18)
	keys_box.add_theme_constant_override("separation", 6)
	root.add_child(keys_box)

	toast_label = _make_label(root, Vector2(0, 0), 24)
	toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_label.position = Vector2(0, 96)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_label.visible = false

	prompt_label = _make_label(root, Vector2(0, 0), 22)
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.position = Vector2(0, -70)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	prompt_label.visible = false

	_build_boss_panel(root)
	_build_controls_panel(root)


func _build_boss_panel(root: Control) -> void:
	boss_panel = PanelContainer.new()
	boss_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_panel.position = Vector2(0, 24)
	boss_panel.custom_minimum_size = Vector2(560, 60)
	boss_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	boss_panel.visible = false
	var box := VBoxContainer.new()
	boss_panel.add_child(box)
	boss_name_label = Label.new()
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.add_theme_font_size_override("font_size", 20)
	box.add_child(boss_name_label)
	boss_bar = ProgressBar.new()
	boss_bar.custom_minimum_size = Vector2(520, 20)
	boss_bar.max_value = 1.0
	boss_bar.value = 1.0
	boss_bar.show_percentage = false
	box.add_child(boss_bar)
	root.add_child(boss_panel)


func _build_controls_panel(root: Control) -> void:
	controls_panel = PanelContainer.new()
	controls_panel.set_anchors_preset(Control.PRESET_CENTER)
	controls_panel.position = Vector2(0, 40)
	controls_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	controls_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	controls_panel.visible = false
	var text := Label.new()
	text.text = "CONTROLS\nA / D or \u2190 \u2192  Move\nSPACE  Jump\nE  Interact / Enter portal\nF  Anti-physics ability\nMouse  Shoot (once armed)\nR  Restart level    Esc  Pause"
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 20)
	controls_panel.add_child(text)
	root.add_child(controls_panel)


func _make_label(parent: Control, pos: Vector2, size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(1, 1, 1))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	l.add_theme_constant_override("outline_size", 6)
	parent.add_child(l)
	return l


## ---- Updates --------------------------------------------------------------

func _on_hearts_changed(hearts: int, max_hearts: int) -> void:
	if hearts_box == null:
		return
	for c in hearts_box.get_children():
		c.queue_free()
	var tex: Texture2D = load(HEART_TEX)
	for i in max_hearts:
		var icon := TextureRect.new()
		icon.texture = tex
		icon.custom_minimum_size = Vector2(26, 26)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = Color.WHITE if i < hearts else Color(0.25, 0.25, 0.25, 0.7)
		hearts_box.add_child(icon)


func _refresh_cherries() -> void:
	if cherry_label != null:
		cherry_label.text = "%d cherries" % GameState.total_cherries


func _refresh_ammo() -> void:
	if ammo_label == null:
		return
	if GameState.gun_unlocked:
		ammo_label.text = "Ammo  %d" % GameState.ammo
	else:
		ammo_label.text = "No gun - clear the puzzle"


func _on_ability_changed(display: String, active_now: bool, time_left: float, cooldown: float, is_ready: bool) -> void:
	if ability_label == null:
		return
	if active_now:
		ability_label.text = "F: %s  -  ACTIVE %.1fs" % [display, time_left]
		ability_bar.value = 1.0
		ability_bar.modulate = Color(0.4, 1.0, 0.6)
	elif is_ready:
		ability_label.text = "F: %s  -  READY" % display
		ability_bar.value = 1.0
		ability_bar.modulate = Color(0.5, 0.8, 1.0)
	else:
		ability_label.text = "F: %s  -  CHARGING %.1fs" % [display, cooldown]
		var dur := float(AbilityManager.COOLDOWN.get(_ability_id(), 4.0))
		ability_bar.value = clampf(1.0 - cooldown / maxf(0.1, dur), 0.0, 1.0)
		ability_bar.modulate = Color(1.0, 0.7, 0.3)


func _ability_id() -> String:
	if _fox != null:
		return _fox.ability_manager.ability_id
	return ""


func set_puzzle_title(title: String) -> void:
	if puzzle_label != null:
		puzzle_label.text = "%s  0 / 0" % title


func _on_puzzle_changed(level_index: int, done: int, total: int) -> void:
	if puzzle_label == null or _fox == null:
		return
	if level_index != GameState.current_level:
		return
	var title: String = String(Dimensions.puzzle_for(level_index).get("title", "Puzzle"))
	if done >= total and total > 0:
		puzzle_label.text = "%s  -  SOLVED" % title
		puzzle_label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.6))
	else:
		puzzle_label.text = "%s  %d / %d" % [title, done, total]
		puzzle_label.add_theme_color_override("font_color", Color(1, 1, 1))


func _on_keys_changed(keys: Dictionary) -> void:
	if keys_box == null:
		return
	for c in keys_box.get_children():
		c.queue_free()
	var tex: Texture2D = FX.load_tex(KEY_TEX)
	for id in ["ember", "tide", "thorn", "void"]:
		var icon := TextureRect.new()
		icon.texture = tex
		icon.custom_minimum_size = Vector2(32, 32)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if bool(keys.get(id, false)):
			icon.modulate = Dimensions.key_color(id)
		else:
			icon.modulate = Color(0.3, 0.3, 0.35, 0.5)
		keys_box.add_child(icon)


func show_boss_bar(boss_name: String) -> void:
	boss_name_label.text = boss_name
	boss_panel.visible = true


func hide_boss_bar() -> void:
	boss_panel.visible = false


func set_boss_health(hp: int, max_hp: int) -> void:
	boss_bar.max_value = max_hp
	boss_bar.value = hp


func toast(text: String) -> void:
	toast_label.text = text
	toast_label.visible = true
	_toast_timer = 2.4


func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		toast_label.modulate.a = clampf(_toast_timer, 0.0, 1.0)
		if _toast_timer <= 0.0:
			toast_label.visible = false
	if _controls_timer > 0.0:
		_controls_timer -= delta
		if _controls_timer <= 0.0:
			controls_panel.visible = false
	_update_portal_prompt()


func _update_portal_prompt() -> void:
	if _fox == null or prompt_label == null:
		return
	var visible_now := false
	for p in get_tree().get_nodes_in_group("portal"):
		if p.get("active") == true and _fox.global_position.distance_to(p.global_position) < 120.0:
			visible_now = true
			break
	prompt_label.visible = visible_now
	if visible_now:
		prompt_label.text = "Press  E  to travel onward"
