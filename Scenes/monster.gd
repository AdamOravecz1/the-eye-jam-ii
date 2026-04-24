extends CharacterBody2D

@export var speed: float = 200.0
@export var gravity: float = 800.0
@export var acceleration: float = 800.0
@export var deceleration: float = 300.0

var health = 3

var dir = 1

@onready var player = get_tree().get_first_node_in_group("Player")

func _ready() -> void:
	$Timer.wait_time = randf_range(3, 6)

func _physics_process(delta):

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	if health > 0:
		if velocity.x == 0:
			$AnimationPlayer.play("Idle")
		else:
			$AnimationPlayer.play("Run")
		var target_direction = sign(player.global_position.x - global_position.x)

		
		if dir != target_direction:
			if scale.x == 1.0:
				scale.x = -1.0
			else:
				scale.x = 1.0
			dir = target_direction
			
		var target_speed = target_direction * speed

		# Choose acceleration or deceleration depending on direction change
		if sign(velocity.x) == target_direction or velocity.x == 0:
			# same direction → accelerate
			velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
		else:
			# opposite direction → slow down before turning
			velocity.x = move_toward(velocity.x, target_speed, deceleration * delta)

	move_and_slide()


func _on_hitbox_area_entered(area: Area2D) -> void:
	health -= 1

	if health <= 0:
		$BodyPivot/HeadPivot/Head.frame = 4

		
		collision_layer = 1 << 5
		collision_mask = 1 << 5
		velocity.x = 0

		$Hitbox/CollisionShape2D.set_deferred("disabled", true)
		$AnimationPlayer.play("Death")


func _on_timer_timeout() -> void:
	if health > 0:
		$Growl.play()
