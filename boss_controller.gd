extends CharacterBody2D
class_name Boss
## Guardian beast that protects each realm's portal.
##
## A small state machine (hover / telegraph / attack / recover) drives distinct
## attack patterns per realm. The boss is invulnerable while lunging and while
## the fox is outside the arena, so it cannot be sniped through walls.

signal health_changed(hp: int, max_hp: int)
signal defeated
signal engaged
signal phase_changed(phase: int)

const PROJ_SCENE := "res://scenes/weapons/boss_projectile.tscn"

var boss_name := "Guardian"
var max_hp := 12
var hp := 12
var proj_color := Color(1.0, 0.5, 0.1)
var arena_x0 := 0.0
var arena_x1 := 100.0
var home_y := 500.0
var hover_radius := 16.0
var max_phase := 1
var phase := 1

var active := false
var _player: Fox
var _proj_scene: PackedScene
var _state := "sleep"
var _timer := 0.0
var _invuln := 0.0
var _facing := -1
var _t := 0.0
var _flash := 0.0
var _dead := false
var _shots := 0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("boss")
	_proj_scene = load(PROJ_SCENE)
	_t = randf() * TAU


func setup(cfg: Dictionary) -> void:
	boss_name = String(cfg.get("name", boss_name))
	max_hp = int(cfg.get("hp", max_hp))
	hp = max_hp
	proj_color = cfg.get("proj_color", proj_color)
	arena_x0 = float(cfg.get("arena_x0", arena_x0))
	arena_x1 = float(cfg.get("arena_x1", arena_x1))
	home_y = float(cfg.get("y", home_y))
	max_phase = maxi(1, int(cfg.get("phases", 1)))
	phase = 1
	if sprite != null:
		var tex_path := String(cfg.get("tex", ""))
		sprite.texture = FX.load_tex(tex_path)


func is_engaged() -> bool:
	return active and not _dead


func is_alive() -> bool:
	return not _dead


func _physics_process(delta: float) -> void:
	_t += delta
	_update_flash(delta)
	_invuln = maxf(0.0, _invuln - delta)

	if _dead:
		return

	_player = _find_player()

	if not active:
		position.y = home_y + sin(_t * 1.5) * hover_radius * 0.5
		sprite.rotation = sin(_t * 1.2) * 0.03
		if _player != null and _player.global_position.x > arena_x0 - 140.0 \
				and _player.global_position.x < arena_x1 + 60.0:
			_engage()
		return

	_timer -= delta
	match _state:
		"hover":
			_hover(delta)
			if _timer <= 0.0:
				_choose_attack()
		"telegraph":
			_hover(delta, 0.3)
			if _timer <= 0.0:
				_execute_attack()
		"lunge":
			_lunge(delta)
			if _timer <= 0.0:
				_to_hover(0.6)
		"teleport":
			_hover(delta, 0.0)
			if _timer <= 0.0:
				_execute_teleport()
		"recover":
			_hover(delta, 0.5)
			if _timer <= 0.0:
				_to_hover(0.2)
	_check_contact()


func _hover(delta: float, speed_scale: float = 1.0) -> void:
	var target_x := position.x
	if _player != null:
		target_x = clampf(_player.global_position.x, arena_x0 + 70.0, arena_x1 - 70.0)
	position.x = move_toward(position.x, target_x, 150.0 * delta * speed_scale)
	var target_y := home_y + sin(_t * 1.6) * hover_radius
	position.y = move_toward(position.y, target_y, 220.0 * delta)
	_face_player()
	sprite.rotation = sin(_t * 2.0) * 0.04


func _face_player() -> void:
	if _player == null:
		return
	_facing = 1 if _player.global_position.x > global_position.x else -1
	sprite.flip_h = _facing < 0


func _to_hover(wait: float) -> void:
	_state = "hover"
	_timer = wait + randf() * 0.4


func _choose_attack() -> void:
	var r := randf()
	if phase >= 2 and max_phase >= 2 and r < 0.22:
		_state = "teleport"
		_timer = 0.45
		_shots = 3
		_begin_telegraph(Color(0.8, 0.5, 1.0))
		return
	if r < 0.42:
		_state = "telegraph"
		_timer = maxf(0.28, 0.55 - (phase - 1) * 0.08)
		_shots = 0
		_begin_telegraph(Color(1.0, 1.0, 0.5))
	elif r < 0.75:
		_state = "telegraph"
		_timer = maxf(0.3, 0.5 - (phase - 1) * 0.06)
		_shots = 1
		_begin_telegraph(Color(1.0, 0.6, 0.4))
	else:
		_state = "telegraph"
		_timer = maxf(0.34, 0.6 - (phase - 1) * 0.06)
		_shots = 2
		_begin_telegraph(Color(0.7, 0.8, 1.0))


func _execute_teleport() -> void:
	AudioManager.play_sfx("ability", 0.6)
	FX.burst(get_parent(), global_position, proj_color, 14, 220.0)
	var target_x := position.x
	if _player != null:
		target_x = _player.global_position.x + (120.0 if _facing < 0 else -120.0)
	position.x = clampf(target_x, arena_x0 + 60.0, arena_x1 - 60.0)
	position.y = home_y - 20.0
	FX.burst(get_parent(), global_position, proj_color, 16, 240.0)
	_face_player()
	_fire_volley(3 + phase, 0.16, 300.0 + phase * 20.0)
	_to_hover(0.45)


func _begin_telegraph(color: Color) -> void:
	_flash = 0.18
	sprite.modulate = color
	var t := create_tween()
	t.tween_property(sprite, "scale", Vector2(1.12, 1.12), 0.12)
	t.tween_property(sprite, "scale", Vector2.ONE, 0.12)


func _execute_attack() -> void:
	match _shots:
		0:
			_fire_volley(3, 0.0, 300.0)
			_to_hover(0.7)
		1:
			_start_lunge()
		2:
			_shockwave()


func _fire_volley(count: int, spread: float, speed: float) -> void:
	var origin := global_position + Vector2(0, -10)
	var base_angle := 0.0
	if _player != null:
		base_angle = (origin.direction_to(_player.global_position)).angle()
	for i in count:
		var a := base_angle + (float(i) - (count - 1) * 0.5) * spread
		_spawn_projectile(origin, Vector2.RIGHT.rotated(a), speed)
	AudioManager.play_sfx("shoot", 0.7)


func _start_lunge() -> void:
	_state = "lunge"
	_timer = 0.55
	_invuln = 1.2
	var dir := Vector2(-1, 0) if _facing < 0 else Vector2(1, 0)
	if _player != null:
		dir = global_position.direction_to(_player.global_position)
		dir = Vector2(signf(dir.x), clampf(dir.y, -0.4, 0.4)).normalized()
	velocity = dir * 620.0
	AudioManager.play_sfx("ability", 0.7)


func _lunge(delta: float) -> void:
	position += velocity * delta
	position.x = clampf(position.x, arena_x0 - 40.0, arena_x1 - 20.0)
	position.y = move_toward(position.y, home_y, 40.0 * delta)


func _shockwave() -> void:
	var y := position.y + 60.0
	for i in 6:
		var side := -1.0 if i % 2 == 0 else 1.0
		var origin := Vector2(position.x + side * (40.0 + i * 26.0), y)
		_spawn_projectile(origin, Vector2(side, -0.15).normalized(), 240.0)
	_to_hover(0.8)
	AudioManager.play_sfx("shoot", 0.55)


func _spawn_projectile(pos: Vector2, dir: Vector2, speed: float) -> void:
	if _proj_scene == null:
		return
	var root := get_tree().current_scene
	if root == null:
		root = get_parent()
	var b := _proj_scene.instantiate()
	root.add_child(b)
	b.global_position = pos
	if "proj_color" in b:
		b.proj_color = proj_color
	if b.has_method("setup"):
		b.setup(dir, speed)


func _check_contact() -> void:
	if _player == null or not _player.can_control:
		return
	if global_position.distance_to(_player.global_position) < 66.0:
		if _player.take_damage(1, global_position):
			Fx_hit()


func Fx_hit() -> void:
	FX.burst(get_parent(), global_position, proj_color, 10, 180.0)


func take_damage(amount: int) -> void:
	if _dead or _invuln > 0.0:
		return
	# Cannot be damaged from outside the intended arena.
	if _player != null and (_player.global_position.x < arena_x0 or _player.global_position.x > arena_x1 + 40.0):
		return
	hp = maxi(0, hp - amount)
	_flash = 0.12
	sprite.modulate = Color(1.0, 0.5, 0.5)
	health_changed.emit(hp, max_hp)
	_update_phase()
	if hp <= 0:
		_die()


func _update_phase() -> void:
	if max_phase <= 1 or max_hp <= 0:
		return
	var want := 1 + int(floor((1.0 - float(hp) / float(max_hp)) * float(max_phase)))
	want = clampi(want, 1, max_phase)
	if want != phase:
		phase = want
		phase_changed.emit(phase)
		AudioManager.play_sfx("boss_intro", 1.2)


func _die() -> void:
	_dead = true
	active = false
	collision_layer = 0
	defeated.emit()
	AudioManager.play_sfx("boss_defeat")
	FX.ring(get_parent(), global_position, proj_color, 90.0)
	for i in 5:
		FX.burst(get_parent(), global_position + Vector2(randf_range(-60, 60), randf_range(-40, 40)), proj_color, 10, 200.0)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(self, "modulate:a", 0.0, 1.4)
	t.tween_property(self, "scale", Vector2(1.3, 0.4), 1.4)
	t.chain().tween_callback(queue_free)


func _engage() -> void:
	active = true
	_state = "hover"
	_timer = 1.0
	invuln_intro()
	health_changed.emit(hp, max_hp)
	engaged.emit()
	AudioManager.play_sfx("boss_intro")


func invuln_intro() -> void:
	_invuln = 0.8


func _update_flash(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta)
		if _flash <= 0.0 and not _dead:
			sprite.modulate = Color.WHITE


func _find_player() -> Fox:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0] as Fox
