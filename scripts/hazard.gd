extends Area2D
## Static damaging zone (lava pool, void pit, spikes). Snaps the fox back to
## its last safe footing after taking a heart.

var hazard_color := Color(1.0, 0.3, 0.05)

@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var visual: ColorRect = $Visual


func _ready() -> void:
	add_to_group("hazard")
	body_entered.connect(_on_body_entered)


func configure(size: Vector2, color: Color) -> void:
	hazard_color = color
	var shape := RectangleShape2D.new()
	shape.size = size
	collider.shape = shape
	visual.size = size
	visual.position = -size * 0.5
	visual.color = color


func _on_body_entered(body: Node) -> void:
	if body is Fox:
		(body as Fox).hazard_hit(1)
