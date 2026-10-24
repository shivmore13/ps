class_name FX
extends RefCounted
## Tiny one-shot particle helper used for pickups, impacts and death puffs.

## Load a texture, falling back to decoding the PNG directly if the file has not
## been through Godot's import pipeline (keeps the game working no matter what).
static func load_tex(path: String) -> Texture2D:
	if path == "":
		return null
	if not FileAccess.file_exists(path):
		return null
	var tex: Texture2D = null
	# Prefer the imported resource when the import pipeline has processed the file.
	if FileAccess.file_exists(path + ".import"):
		tex = load(path)
	if tex == null:
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null:
			tex = ImageTexture.create_from_image(img)
	return tex


static func burst(parent: Node, pos: Vector2, color: Color, count: int = 12, speed: float = 170.0) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var p := CPUParticles2D.new()
	p.amount = count
	p.lifetime = 0.5
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.35
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, 340)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.2
	p.color = color
	p.z_index = 5
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	var t := p.create_tween()
	t.tween_interval(1.1)
	t.tween_callback(p.queue_free)


static func ring(parent: Node, pos: Vector2, color: Color, radius: float = 40.0) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var p := CPUParticles2D.new()
	p.amount = 24
	p.lifetime = 0.45
	p.one_shot = true
	p.explosiveness = 1.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 4.0
	p.spread = 180.0
	p.initial_velocity_min = radius * 3.0
	p.initial_velocity_max = radius * 5.0
	p.gravity = Vector2.ZERO
	p.scale_amount_min = 1.2
	p.scale_amount_max = 2.0
	p.color = color
	p.z_index = 5
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	var t := p.create_tween()
	t.tween_interval(1.0)
	t.tween_callback(p.queue_free)
