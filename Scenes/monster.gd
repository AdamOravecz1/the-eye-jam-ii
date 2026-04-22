extends CharacterBody2D


@export var speed: float = 200.0

func _physics_process(delta):
	velocity.x = -speed
	velocity.y = 0
	move_and_slide()
