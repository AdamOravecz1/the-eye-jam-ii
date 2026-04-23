extends CharacterBody2D

const dead_head_scene := preload("res://Scenes/dead_head.tscn")

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
@onready var muzzle_flash = $WeaponAnchorPoint/RecoilAnchorPoint/Weapon/BarrelEnd/PointLight2D

var alive = true

var ammo = 9
var loaded_in = 8
var reloading = false

func _process(delta):
	apply_gravity(delta)
	if alive:
		get_input()
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
	if Input.is_action_just_pressed("shoot") and loaded_in > 0 and not reloading:
		muzzle_flash.visible = true
		await get_tree().process_frame
		muzzle_flash.visible = false
		loaded_in -= 1
		weapon.play("shoot")
		update_ammo_count()
		shoot.emit($WeaponAnchorPoint/RecoilAnchorPoint/Weapon/BarrelEnd.global_position, weapon_anchor.rotation + $WeaponAnchorPoint/RecoilAnchorPoint.rotation )
		if weapon.flip_v:
			recoil_rotation = recoil_angle
		else:
			recoil_rotation = -recoil_angle
	
	# reload
	if Input.is_action_just_pressed("reload") and loaded_in < 8:
		reloading = true
		weapon.position.x = 30
		await get_tree().create_timer(1.0, false).timeout
		var needed = 8 - loaded_in
		if needed <= 0:
			return # already full

		var to_load = min(needed, ammo)

		loaded_in += to_load
		ammo -= to_load
	
		weapon.position.x = 41
		update_ammo_count()
		reloading = false
		
	if Input.is_action_just_pressed("death"):
		death()
		

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
	
func update_ammo_count():
	$CanvasLayer/Ammo.text = str(ammo) + "/" + str(loaded_in)
	
func death():
	print("death")
	alive = false
	body_sprite.play("dead")
	$Head.visible = false

	var dead_head := dead_head_scene.instantiate()
	add_child(dead_head)
	dead_head.position.y -= 32
	$GPUParticles2D.emitting = true

	var random_x := randf_range(-100, 100)
	var upward := randf_range(-200, -350)

	dead_head.apply_impulse(Vector2(random_x, upward))
	
	
