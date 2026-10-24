extends CharacterBody2D
class_name Fox
## The white fox hero: movement, jumping, health, shooting and interaction.
##
## Physics is hand-tuned (custom gravity, coyote time, jump buffering, variable
## jump height) so the platforming feels responsive. Gravity direction can be
## flipped by the AbilityManager for the gravity-reversal puzzles.

signal died
signal respawned
signal shot_fired

const SPEED := 300.0
const ACCEL := 2200.0
const FRICTION := 2600.0
const AIR_ACCEL := 1500.0
const JUMP_VELOCITY := 660.0
const GRAVITY := 1600.0
const FALL_MULT := 1.35
const LOW_JUMP_MULT := 0.45
const MAX_FALL := 1250.0
const COYOTE_TIME := 0.10
const JUMP_BUFFER := 0.12
const INVULN_TIME := 1.4
const SHOOT_COOLDOWN := 0.22
const PROJECTILE_PATH := "res://scenes/weapons/projectile.tscn"

var facing := 1
var gravity_dir := 1  # 1 = normal (down), -1 = reversed (up)
var is_dead := false
var can_control := true
var invuln := 0.0
var _coyote := 0.0
var _jump_buffer := 0.0
var _shoot_cd := 0.0
var _hurt_timer := 0.0
var _last_safe := Vector2.ZERO
var _safe_timer := 0.0
var _projectile_scene: PackedScene

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var camera: Camera2D = $Camera2D
@onready var muzzle: Marker2D = $Muzzle
@onready var ability_manager: AbilityManager = $AbilityManager
@onready var crown: Sprite2D = $AnimatedSprite2D/Crown
@onready var cape: Sprite2D = $AnimatedSprite2D/Cape
var _crown_base := Vector2.ZERO
var _cape_base := Vector2.ZERO


func _ready() -> void:
	add_to_group("player")
	_projectile_scene = load(PROJECTILE_PATH)
	_last_safe = global_position
	_crown_base = crown.position
	_cape_base = cape.position
	sprite.play("idle")


func _physics_process(delta: float) -> void:
	_tick_timers(delta)

	if is_dead:
		_apply_gravity(delta)
		move_and_slide()
		return

	_handle_ability_input()
	_handle_horizontal(delta)
	_handle_jump(delta)
	_apply_gravity(delta)
	_handle_shooting(delta)
	move_and_slide()
	_update_animation()
	_track_safe_position(delta)
	_update_invuln_flash()


func _tick_timers(delta: float) -> void:
	invuln = maxf(0.0, invuln - delta)
	_shoot_cd = maxf(0.0, _shoot_cd - delta)
	_hurt_timer = maxf(0.0, _hurt_timer - delta)
	_coyote = maxf(0.0, _coyote - delta)
	_jump_buffer = maxf(0.0, _jump_buffer - delta)


func _handle_ability_input() -> void:
	if can_control and Input.is_action_just_pressed("ability"):
		if ability_manager != null:
			ability_manager.activate()


func _handle_horizontal(delta: float) -> void:
	var dir := 0.0
	if can_control and _hurt_timer <= 0.0:
		dir = Input.get_axis("move_left", "move_right")
	var accel := ACCEL if is_on_floor() else AIR_ACCEL
	if absf(dir) > 0.01:
		velocity.x = move_toward(velocity.x, dir * SPEED, accel * delta)
		facing = 1 if dir > 0.0 else -1
	else:
		var fric := FRICTION if is_on_floor() else AIR_ACCEL * 0.6
		velocity.x = move_toward(velocity.x, 0.0, fric * delta)


func _handle_jump(_delta: float) -> void:
	if can_control and Input.is_action_just_pressed("jump"):
		_jump_buffer = JUMP_BUFFER
	if is_on_floor():
		_coyote = COYOTE_TIME
	if _jump_buffer > 0.0 and _coyote > 0.0 and _hurt_timer <= 0.0:
		velocity.y = -JUMP_VELOCITY * gravity_dir
		_jump_buffer = 0.0
		_coyote = 0.0
		AudioManager.play_sfx("jump")
	if Input.is_action_just_released("jump"):
		# variable jump height: cut the rise short when the key is released
		if velocity.y * gravity_dir < 0.0:
			velocity.y *= LOW_JUMP_MULT


func _apply_gravity(delta: float) -> void:
	var g := GRAVITY
	if velocity.y * gravity_dir > 0.0:  # falling toward the current floor
		g *= FALL_MULT
	velocity.y += g * gravity_dir * delta
	velocity.y = clampf(velocity.y, -MAX_FALL, MAX_FALL)


func _handle_shooting(_delta: float) -> void:
	if not GameState.gun_unlocked or is_dead:
		return
	if not can_control or _hurt_timer > 0.0:
		return
	if Input.is_action_pressed("shoot") and _shoot_cd <= 0.0:
		if GameState.spend_ammo(1):
			_fire()


func _fire() -> void:
	_shoot_cd = SHOOT_COOLDOWN
	var scene_root := get_tree().current_scene
	if scene_root == null:
		scene_root = get_parent()
	if scene_root == null:
		scene_root = self
	var origin := global_position if muzzle == null else muzzle.global_position
	if _projectile_scene != null:
		var bullet := _projectile_scene.instantiate()
		scene_root.add_child(bullet)
		bullet.global_position = origin
		if bullet.has_method("setup"):
			bullet.setup(Vector2(facing, 0.0))
	FX.burst(scene_root, origin, Color(0.8, 0.95, 1.0), 6, 120.0)
	AudioManager.play_sfx("shoot", randf_range(0.94, 1.06))
	shot_fired.emit()


func _update_animation() -> void:
	if is_dead:
		return
	if _hurt_timer > 0.0:
		_play("hurt")
		return
	var on_floor := is_on_floor()
	var speed_x := absf(velocity.x)
	if not on_floor:
		# moving away from the floor = rising, toward it = falling
		var rising := velocity.y * gravity_dir < 0.0
		_play("jump" if rising else "fall")
	elif speed_x > 12.0:
		_play("run")
		sprite.speed_scale = clampf(speed_x / SPEED, 0.7, 1.5)
	else:
		_play("idle")
		sprite.speed_scale = 1.0


func _play(anim: String) -> void:
	if sprite.animation != anim:
		sprite.play(anim)
	sprite.flip_h = facing < 0
	sprite.flip_v = gravity_dir < 0
	_update_attachments()


## flip_v on the AnimatedSprite2D only mirrors its own texture, not its child
## nodes. Mirror the crown and cape by hand so they stay attached to the head
## when gravity (and the whole body) flips upside down.
func _update_attachments() -> void:
	if crown == null or cape == null:
		return
	var up := gravity_dir > 0
	var sx := -1.0 if facing < 0 else 1.0
	var sy := 1.0 if up else -1.0
	crown.position = Vector2(_crown_base.x * sx, _crown_base.y * sy)
	crown.flip_h = facing < 0
	crown.flip_v = not up
	cape.position = Vector2(_cape_base.x * sx, _cape_base.y * sy)
	cape.flip_h = facing < 0
	cape.flip_v = not up


func _track_safe_position(delta: float) -> void:
	_safe_timer -= delta
	if _safe_timer <= 0.0 and is_on_floor() and invuln <= 0.0:
		_last_safe = global_position
		_safe_timer = 0.35


func _update_invuln_flash() -> void:
	if invuln > 0.0:
		sprite.modulate.a = 0.45 if fmod(invuln, 0.2) > 0.1 else 1.0
	else:
		sprite.modulate.a = 1.0


## ---- Public API -----------------------------------------------------------

func set_gravity_dir(d: int) -> void:
	gravity_dir = 1 if d >= 0 else -1
	# up_direction points AWAY from the current floor, so it flips with gravity.
	up_direction = Vector2(0, -gravity_dir)
	if gravity_dir < 0:
		velocity.y = minf(velocity.y, 0.0)
	else:
		velocity.y = maxf(velocity.y, 0.0)


func snapshot() -> Dictionary:
	return {"gravity_dir": gravity_dir, "facing": facing}


func restore_state(state: Dictionary) -> void:
	set_gravity_dir(int(state.get("gravity_dir", 1)))
	facing = int(state.get("facing", 1))


## Apply damage with knockback + invulnerability frames. Returns true if it landed.
func take_damage(amount: int = 1, from: Vector2 = Vector2.ZERO) -> bool:
	if is_dead or invuln > 0.0:
		return false
	GameState.damage(amount)
	invuln = INVULN_TIME
	_hurt_timer = 0.3
	var away := 1.0
	if from != Vector2.ZERO:
		away = signf(global_position.x - from.x)
		if away == 0.0:
			away = -facing
	velocity.x = away * 260.0
	velocity.y = -220.0 * gravity_dir
	AudioManager.play_sfx("hurt")
	if GameState.is_dead():
		die()
	return true


## Hazard contact: lose a heart and snap back to the last safe footing.
func hazard_hit(amount: int = 1) -> void:
	if is_dead:
		return
	if not take_damage(amount):
		return
	if is_dead:
		return  # the hit was fatal - the game-over flow takes over
	respawn(_last_safe)


func respawn(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	set_gravity_dir(1)
	invuln = INVULN_TIME
	is_dead = false
	can_control = true
	sprite.modulate.a = 1.0
	_play("idle")
	respawned.emit()


func die() -> void:
	if is_dead:
		return
	is_dead = true
	can_control = false
	velocity = Vector2.ZERO
	if sprite.sprite_frames.has_animation("die"):
		sprite.play("die")
	AudioManager.play_sfx("death")
	AudioManager.stop_music()
	died.emit()


func celebrate() -> void:
	can_control = false
	velocity.x = 0.0
	if sprite.sprite_frames.has_animation("victory"):
		sprite.play("victory")


func set_control(enabled: bool) -> void:
	can_control = enabled
	if not enabled:
		velocity.x = 0.0
