extends CharacterBody2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	# gravity for frog
	velocity.y += gravity * delta
	move_and_slide()
func _on_player_detection_body_entered(body):
	if body.name == "Bot" :
		print("Bot")
