extends CharacterBody2D

signal shoot(pos, dir)

@export_group('move')
@export var speed := 200
@export var acceleration := 700
@export var friction := 900
var direction := Vector2.ZERO
var can_move := true

@export_group('jump')
@export var jump_strength := 300
@export var gravity := 600
@export var terminal_velocity := 500
var jump := false
var faster_fall := false
var gravity_multiplier := 1

@export var recoil_angle := deg_to_rad(15) # how much it kicks up
@export var recoil_speed := 12.0

var recoil_rotation := 0.0

@onready var body_sprite = $Body
@onready var head_sprite = $Head

@onready var weapon: AnimatedSprite2D = $WeaponAnchorPoint/RecoilAnchorPoint/Weapon
@onready var weapon_anchor = $WeaponAnchorPoint

func _process(delta):
	get_input()
	apply_gravity(delta)
	apply_movement(delta)
	rotate_weapon()
	update_recoil(delta)
	move_and_slide()
		
	
func get_input():
	# horizontal movement 
	direction.x = Input.get_axis("left", "right")
	if direction.x == 1.0:
		body_sprite.flip_h = false
	elif direction.x == -1.0:
		body_sprite.flip_h = true
	
	if not is_on_floor():
		body_sprite.play("jump")
		head_sprite.play("jump")
	elif direction.x != 0.0:
		body_sprite.play("run")
		head_sprite.play("run")
	else:
		body_sprite.play("idle")
		head_sprite.play("idle")
	
	# jump 
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or $Timers/Coyote.time_left:
			jump = true
		
		if velocity.y > 0 and not is_on_floor():
			$Timers/JumpBuffer.start()
		
	if Input.is_action_just_released("jump") and not is_on_floor() and velocity.y < 0:
		faster_fall = true
		
	# shoot
	if Input.is_action_just_pressed("shoot"):
		weapon.play("shoot")
		shoot.emit($WeaponAnchorPoint/RecoilAnchorPoint/Weapon/BarrelEnd.global_position, weapon_anchor.rotation + $WeaponAnchorPoint/RecoilAnchorPoint.rotation )
		if weapon.flip_v:
			recoil_rotation = recoil_angle
		else:
			recoil_rotation = -recoil_angle
		

func apply_gravity(delta):
	velocity.y += gravity * delta
	velocity.y = velocity.y / 2 if faster_fall and velocity.y < 0 else velocity.y
	velocity.y = velocity.y * gravity_multiplier
	velocity.y = min(velocity.y, terminal_velocity)
	
func apply_movement(delta):
	# left/right movement 
	if direction.x:
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	
	# jump 
	if jump or $Timers/JumpBuffer.time_left and is_on_floor():
		velocity.y = -jump_strength
		jump = false
		faster_fall = false
	
	var on_floor = is_on_floor()
	if on_floor and not is_on_floor() and velocity.y >= 0:
		$Timers/Coyote.start()
		
func rotate_weapon():
	var mouse_pos = get_global_mouse_position()
	weapon_anchor.look_at(mouse_pos)
	
	if get_global_mouse_position().x > global_position.x:
		weapon.flip_v = false
		$WeaponAnchorPoint/RecoilAnchorPoint/Weapon/BarrelEnd.position.y = -5
		$Head.flip_h = false
	else:
		weapon.flip_v = true
		$WeaponAnchorPoint/RecoilAnchorPoint/Weapon/BarrelEnd.position.y = 5
		$Head.flip_h = true
		
func update_recoil(delta):
	recoil_rotation = lerp(recoil_rotation, 0.0, recoil_speed * delta)
	$WeaponAnchorPoint/RecoilAnchorPoint.rotation = recoil_rotation
		
