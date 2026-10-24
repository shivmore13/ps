extends Node2D
class_name LevelBase
## Builds and runs a single realm from the Levels data table.
##
## Everything in a level (terrain, hazards, cherries, seal, gun, boss, portal,
## HUD and menus) is generated here in code so the four realms share one
## reliable, testable pipeline instead of four hand-authored scene files.

const PLATFORM_SCENE := "res://scenes/puzzles/platform.tscn"
const CHERRY_SCENE := "res://scenes/collectibles/cherry.tscn"
const HEART_SCENE := "res://scenes/collectibles/heart_pickup.tscn"
const AMMO_SCENE := "res://scenes/collectibles/ammo_pickup.tscn"
const GUN_SCENE := "res://scenes/collectibles/gun_pickup.tscn"
const HAZARD_SCENE := "res://scenes/hazards/hazard.tscn"
const HAZARD_MOVING_SCENE := "res://scenes/hazards/hazard_moving.tscn"
const PORTAL_SCENE := "res://scenes/effects/portal.tscn"
const GATE_SCENE := "res://scenes/puzzles/gate.tscn"
const BOSS_SCENE := "res://scenes/bosses/boss.tscn"
const FOX_SCENE := "res://scenes/fox.tscn"
const HUD_SCENE := "res://scenes/ui/hud.tscn"
const PAUSE_SCENE := "res://scenes/ui/pause_menu.tscn"
const GAME_OVER_SCENE := "res://scenes/ui/game_over.tscn"
const VICTORY_SCENE := "res://scenes/ui/victory.tscn"
const ENDING_SCENE := "res://scenes/ui/ending.tscn"
const CUTSCENE_SCENE := "res://scenes/cinematics/cutscene.tscn"
const KEY_PICKUP_SCENE := "res://scenes/collectibles/key_pickup.tscn"
const LEVEL_SCENE := "res://scenes/levels/level.tscn"
const KEY_TEX := "res://Assets/generated/prop_key.png"
const CAGE_TEX := "res://Assets/generated/prop_cage.png"
const QUEEN_TEX := "res://Assets/generated/queen_worried.png"

## Set to a realm index to force that realm when the scene is run directly.
## -1 means "use GameState.current_level" (normal flow).
@export var override_index: int = -1

var data: Dictionary
var level_index := 0
var fox: Fox
var boss: Boss
var portal: Node2D
var gate: Node2D
var hud: HUD
var puzzle: PuzzleManager
var cage: Sprite2D
var _terrain: Node2D
var _entities: Node2D
var _platforms: Array = []
var _checkpoint := Vector2.ZERO
var _transitioning := false
var _music_boss := false

var _scenes: Dictionary = {}


func _ready() -> void:
	level_index = override_index if override_index >= 0 else GameState.current_level
	level_index = clampi(level_index, 0, Levels.LEVELS.size() - 1)
	GameState.current_level = level_index
	data = Levels.LEVELS[level_index]
	GameState.begin_level(level_index)
	_checkpoint = _vec2(data.spawn)

	_scenes = {
		"platform": load(PLATFORM_SCENE), "cherry": load(CHERRY_SCENE),
		"heart": load(HEART_SCENE), "ammo": load(AMMO_SCENE),
		"gun": load(GUN_SCENE), "hazard": load(HAZARD_SCENE),
		"hazard_moving": load(HAZARD_MOVING_SCENE), "portal": load(PORTAL_SCENE),
		"gate": load(GATE_SCENE), "boss": load(BOSS_SCENE),
	}

	_build_background()
	_terrain = Node2D.new()
	_terrain.name = "Terrain"
	add_child(_terrain)
	_entities = Node2D.new()
	_entities.name = "Entities"
	add_child(_entities)

	_build_terrain()
	_build_hazards()
	_build_collectibles()
	_build_gate_and_gun()
	_build_puzzle()
	_build_special_key()
	_build_cage()
	_spawn_boss()
	_build_portal()
	_build_hints()
	_spawn_fox()
	_build_ui()

	AudioManager.play_music(String(data.music))
	_maybe_play_intro()


func _process(_delta: float) -> void:
	if _transitioning or fox == null or not is_instance_valid(fox):
		return
	# Keep the fox inside the level and out of the endless void.
	var p := fox.global_position
	var y_limit: float = float(data.height) + 140.0
	if p.y > y_limit or p.y < -260.0:
		fox.hazard_hit(1)
		return
	if p.x < 44.0 or p.x > float(data.width) - 44.0:
		fox.global_position.x = clampf(p.x, 44.0, float(data.width) - 44.0)


func _unhandled_input(event: InputEvent) -> void:
	if _transitioning:
		return
	if event.is_action_pressed("restart"):
		restart_level()


func _toggle_pause() -> void:
	if hud != null and hud.has_node("PauseMenu"):
		var pm: Node = hud.get_node("PauseMenu")
		if pm.has_method("toggle"):
			pm.toggle()


## ---- Construction ---------------------------------------------------------

func _build_background() -> void:
	var bg := ParallaxBackground.new()
	bg.name = "Background"
	add_child(bg)
	var layer := ParallaxLayer.new()
	layer.motion_scale = Vector2(0.35, 1.0)
	layer.motion_mirroring = Vector2(2560, 0)
	bg.add_child(layer)
	var tex: Texture2D = FX.load_tex(String(data.bg))
	# two mirrored copies side by side make a seamless scrolling backdrop
	var a := Sprite2D.new()
	a.texture = tex
	a.scale = Vector2(2, 2)
	a.position = Vector2(640, 360)
	layer.add_child(a)
	var b := Sprite2D.new()
	b.texture = tex
	b.scale = Vector2(2, 2)
	b.flip_h = true
	b.position = Vector2(1920, 360)
	layer.add_child(b)
	var backdrop := ColorRect.new()
	backdrop.color = data.sky
	backdrop.size = Vector2(float(data.width), float(data.height) + 400.0)
	backdrop.z_index = -100
	bg.add_child(backdrop)


func _build_terrain() -> void:
	var ground_tex: Texture2D = FX.load_tex(String(data.ground))
	var floor_y := float(data.ground_y)
	for seg in data.floor:
		var x := float(seg[0])
		var w := float(seg[1])
		var rect := Rect2(x, floor_y, w, float(data.height) + 80.0 - floor_y)
		_make_platform(rect, TimePlatform.Kind.SOLID, ground_tex)
	for p in data.plats:
		_make_platform(_rect(p), TimePlatform.Kind.SOLID, ground_tex)
	for m in data.movers:
		_make_platform(_rect(m), TimePlatform.Kind.MOVING, ground_tex,
			{"move_offset": Vector2(float(m[4]), float(m[5])), "move_cycle": float(m[6]), "affected": true})
	for c in data.crumbling:
		_make_platform(_rect(c), TimePlatform.Kind.CRUMBLING, ground_tex,
			{"crumble_delay": float(c[4])})
	for d in data.disappear:
		_make_platform(_rect(d), TimePlatform.Kind.DISAPPEARING, ground_tex,
			{"vanish_period": float(d[4]), "vanish_phase": float(d[5])})
	for h in data.hidden:
		_make_platform(_rect(h), TimePlatform.Kind.HIDDEN, ground_tex)


func _make_platform(rect: Rect2, kind: int, tex: Texture2D, cfg: Dictionary = {}) -> TimePlatform:
	var p: TimePlatform = _scenes.platform.instantiate()
	p.configure(kind, rect.size)
	for k in cfg:
		p.set(k, cfg[k])
	p.position = rect.position + rect.size * 0.5
	_terrain.add_child(p)
	var spr: Sprite2D = p.get_node("Sprite2D")
	spr.texture = tex
	spr.region_enabled = true
	spr.region_rect = Rect2(0, 0, rect.size.x, rect.size.y)
	spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	return p


func _build_hazards() -> void:
	for h in data.hazards:
		var rect := _rect(h)
		var area: Area2D = _scenes.hazard.instantiate()
		area.position = rect.position + rect.size * 0.5
		_terrain.add_child(area)
		area.configure(rect.size, data.pit)
	for hm in data.hazard_moving:
		var rect := _rect(hm)
		var area: Area2D = _scenes.hazard_moving.instantiate()
		area.position = rect.position + rect.size * 0.5
		_terrain.add_child(area)
		area.configure(rect.size, data.accent, Vector2(float(hm[4]), float(hm[5])), float(hm[6]))


func _build_collectibles() -> void:
	for c in data.cherries:
		var ch: Cherry = _scenes.cherry.instantiate()
		ch.level_index = level_index
		ch.position = _vec2(c)
		_entities.add_child(ch)
	for a in data.ammo:
		var pk: Node2D = _scenes.ammo.instantiate()
		pk.kind = "ammo"
		pk.position = _vec2(a)
		_entities.add_child(pk)


func _build_gate_and_gun() -> void:
	var g: Array = data.gate
	var rect := _rect(g)
	gate = _scenes.gate.instantiate()
	gate.position = rect.position + rect.size * 0.5
	_entities.add_child(gate)
	gate.configure(rect.size, data.accent)

	var gun: Node2D = _scenes.gun.instantiate()
	gun.position = _vec2(data.gun)
	_entities.add_child(gun)


func _spawn_boss() -> void:
	var cfg: Dictionary = data.boss
	boss = _scenes.boss.instantiate()
	boss.position = Vector2(float(cfg.x), float(cfg.y))
	_entities.add_child(boss)
	boss.setup(cfg)
	boss.health_changed.connect(_on_boss_health)
	boss.engaged.connect(_on_boss_engaged)
	boss.defeated.connect(_on_boss_defeated)
	boss.phase_changed.connect(_on_boss_phase)


func _build_portal() -> void:
	portal = _scenes.portal.instantiate()
	portal.position = _vec2(data.portal)
	_entities.add_child(portal)
	portal.set_active(false)
	portal.entered.connect(_on_portal_entered)


func _build_hints() -> void:
	for h in data.hints:
		var lbl := Label.new()
		lbl.text = String(h[2])
		lbl.position = Vector2(float(h[0]), float(h[1]))
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		lbl.add_theme_constant_override("outline_size", 5)
		lbl.z_index = 20
		_entities.add_child(lbl)


func _spawn_fox() -> void:
	fox = (load(FOX_SCENE) as PackedScene).instantiate() as Fox
	fox.position = _checkpoint
	_entities.add_child(fox)
	fox.died.connect(_on_fox_died)
	fox.shot_fired.connect(_on_fox_shot)
	var cam: Camera2D = fox.camera
	if cam != null:
		cam.limit_left = 0
		cam.limit_top = -200
		cam.limit_right = int(data.width)
		cam.limit_bottom = int(data.height) + 120
		cam.make_current()


func _build_ui() -> void:
	hud = load(HUD_SCENE).instantiate()
	add_child(hud)
	hud.bind(fox, boss, level_index, boss.boss_name)
	hud.add_pause_menu()
	hud.request_controls_guide(level_index == 0)
	if puzzle != null:
		hud.set_puzzle_title(puzzle.title())


## ---- Puzzles & story ------------------------------------------------------

func _build_puzzle() -> void:
	var pcfg: Dictionary = Dimensions.puzzle_for(level_index).duplicate(true)
	pcfg["required_cherries"] = int(data.required_cherries)
	puzzle = PuzzleManager.new()
	puzzle.name = "PuzzleManager"
	add_child(puzzle)
	puzzle.configure(pcfg, _entities, level_index)
	puzzle.solved.connect(_on_puzzle_solved)
	puzzle.failed.connect(_on_puzzle_failed)
	puzzle.message.connect(_on_puzzle_message)
	_build_puzzle_hint()


func _build_puzzle_hint() -> void:
	var objs: Array = puzzle.cfg.get("objects", [])
	if objs.is_empty():
		return
	var pos: Array = objs[0].pos
	var lbl := Label.new()
	lbl.text = "%s\n%s" % [puzzle.title(), puzzle.hint()]
	lbl.position = Vector2(float(pos[0]) - 230.0, float(pos[1]) - 160.0)
	lbl.custom_minimum_size = Vector2(460, 0)
	lbl.add_theme_font_size_override("font_size", 17)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.z_index = 20
	_entities.add_child(lbl)


func _build_special_key() -> void:
	# In the Void the key is not dropped by the boss - it must be found on an
	# optional route up in the rafters, reached by reversing gravity.
	if String(Dimensions.get_data(level_index).boss_key) != "":
		return
	var kp: Node = load(KEY_PICKUP_SCENE).instantiate()
	kp.key_id = "void"
	kp.position = _vec2(Dimensions.get_data(level_index).key_pos)
	_entities.add_child(kp)


func _build_cage() -> void:
	if not bool(Dimensions.get_data(level_index).get("queen", false)):
		return
	var queen := Sprite2D.new()
	queen.texture = FX.load_tex(QUEEN_TEX)
	queen.position = Vector2(3110, 470)
	queen.scale = Vector2(1.6, 1.6)
	queen.z_index = 2
	_entities.add_child(queen)
	cage = Sprite2D.new()
	cage.texture = FX.load_tex(CAGE_TEX)
	cage.position = Vector2(3110, 430)
	cage.scale = Vector2(1.05, 1.05)
	cage.z_index = 3
	_entities.add_child(cage)


func _on_puzzle_solved() -> void:
	if gate != null and is_instance_valid(gate) and not gate.is_open():
		gate.open()
	if hud != null:
		hud.toast("The mechanism completes - the vault opens!")
	AudioManager.play_sfx("key", 0.9)


func _on_puzzle_failed() -> void:
	if hud != null:
		hud.toast("The mechanism resets - try another order.")


func _on_puzzle_message(text: String) -> void:
	if hud != null:
		hud.toast(text)


func _maybe_play_intro() -> void:
	if GameState.intro_seen(level_index):
		return
	GameState.mark_intro_seen(level_index)
	var shots: Array = StoryData.dimension_intro(level_index)
	if shots.is_empty():
		return
	var music := String(data.music)
	_play_cutscene(shots, func() -> void: AudioManager.play_music(music))


func _play_cutscene(shots: Array, on_done: Callable = Callable()) -> void:
	if shots.is_empty():
		if on_done.is_valid():
			on_done.call()
		return
	var cs: Node = load(CUTSCENE_SCENE).instantiate()
	add_child(cs)
	cs.play(shots, on_done)


func _spawn_key_visual(key_id: String) -> void:
	var spr := Sprite2D.new()
	spr.texture = FX.load_tex(KEY_TEX)
	spr.modulate = Dimensions.key_color(key_id)
	spr.position = _vec2(Dimensions.get_data(level_index).key_pos)
	spr.z_index = 30
	_entities.add_child(spr)
	FX.ring(_entities, spr.position, Dimensions.key_color(key_id), 60.0)
	var t := spr.create_tween()
	t.tween_property(spr, "position:y", spr.position.y - 60.0, 1.0)
	t.parallel().tween_property(spr, "modulate:a", 0.0, 1.2)
	t.chain().tween_callback(spr.queue_free)


func _on_boss_phase(phase: int) -> void:
	AudioManager.play_sfx("puzzle_fail", 1.3)
	if hud != null:
		hud.toast("Phase %d - Varkhos tears at the dimensions!" % phase)
	if cage != null and is_instance_valid(cage):
		var t := cage.create_tween()
		t.tween_property(cage, "rotation", 0.06, 0.08)
		t.tween_property(cage, "rotation", -0.06, 0.08)
		t.tween_property(cage, "rotation", 0.0, 0.08)


## ---- Runtime wiring -------------------------------------------------------

func _apply_gate_state() -> void:
	if gate == null or not is_instance_valid(gate):
		return
	var need := int(data.required_cherries)
	if GameState.level_cherries(level_index) >= need:
		gate.open()


func _on_cherries_changed(_total: int) -> void:
	if gate == null or not is_instance_valid(gate) or gate.is_open():
		return
	var need := int(data.required_cherries)
	var got := GameState.level_cherries(level_index)
	if hud != null:
		hud.toast("Cherries %d / %d" % [got, need])
	if got >= need:
		gate.open()
		if hud != null:
			hud.toast("The seal opens - claim the gun!")


func _on_boss_health(hp: int, max_hp: int) -> void:
	if hud != null:
		hud.set_boss_health(hp, max_hp)


func _on_boss_engaged() -> void:
	_music_boss = true
	AudioManager.play_music(String(data.boss_music), true)
	if hud != null:
		hud.show_boss_bar(boss.boss_name)
		hud.toast("%s awakens!" % boss.boss_name)


func _on_boss_defeated() -> void:
	AudioManager.play_music(String(data.music))
	if hud != null:
		hud.hide_boss_bar()
	var key_id := String(Dimensions.get_data(level_index).boss_key)
	if key_id != "":
		GameState.collect_key(key_id)
		AudioManager.play_sfx("key")
		_spawn_key_visual(key_id)
		if hud != null:
			hud.toast("Obtained the %s!" % Dimensions.key_name(key_id))
	var shots: Array = StoryData.clue(level_index)
	if shots.is_empty():
		_activate_portal()
	else:
		_play_cutscene(shots, func() -> void: _activate_portal())


func _activate_portal() -> void:
	if portal != null and is_instance_valid(portal):
		portal.set_active(true)
		FX.ring(portal.get_parent(), portal.global_position, Color(0.7, 0.6, 1.0), 90.0)
	if hud != null:
		hud.toast("The guardian falls - the portal opens!")


func _on_fox_died() -> void:
	if _transitioning:
		return
	_transitioning = true
	await get_tree().create_timer(1.6).timeout
	var go: Node = load(GAME_OVER_SCENE).instantiate()
	add_child(go)
	go.setup(level_index)


func _on_fox_shot() -> void:
	# tiny camera kick for feedback
	if fox != null and fox.camera != null:
		var t := create_tween()
		t.tween_property(fox.camera, "offset", Vector2(-fox.facing * 3.0, 0), 0.04)
		t.tween_property(fox.camera, "offset", Vector2.ZERO, 0.08)


func _on_portal_entered() -> void:
	if _transitioning:
		return
	if GameState.is_last_level():
		_ending()
	else:
		_next_level()


func _next_level() -> void:
	_transitioning = true
	GameState.complete_level(level_index)
	if fox != null:
		fox.set_control(false)
	await get_tree().create_timer(0.6).timeout
	GameState.current_level = level_index + 1
	get_tree().change_scene_to_file(LEVEL_SCENE)


func _ending() -> void:
	_transitioning = true
	GameState.complete_level(level_index)
	GameState.rescue_queen()
	GameState.campaign_complete = true
	GameState.save_game()
	get_tree().paused = false
	if fox != null:
		fox.celebrate()
	AudioManager.stop_music()
	await get_tree().create_timer(1.2).timeout
	var e: Node = load(ENDING_SCENE).instantiate()
	add_child(e)


func restart_level() -> void:
	if _transitioning:
		return
	_transitioning = true
	get_tree().paused = false
	AudioManager.stop_music()
	get_tree().reload_current_scene()


## ---- Helpers --------------------------------------------------------------

func _rect(row: Array) -> Rect2:
	return Rect2(float(row[0]), float(row[1]), float(row[2]), float(row[3]))


func _vec2(row: Array) -> Vector2:
	return Vector2(float(row[0]), float(row[1]))
