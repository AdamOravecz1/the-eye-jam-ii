extends CharacterBody2D

const dead_head_scene := preload("res://Scenes/dead_head.tscn")
@onready var main = get_tree().get_first_node_in_group("Main")


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

@onready var geiger_counter_needle: Sprite2D = $CanvasLayer/GeigerCounterNeedle
var wobble_time := 0.0
var beep_timer := 0.0
var beep_interval := 1.0

var carrying = false
var relic_amount = 0

var alive = true

var ammo = 9
var loaded_in = 8
var reloading = false

var breathing_delay := 0.0
var breathing_active := false

func _ready():
	body_sprite.animation_looped.connect(_on_run_looped)

func _process(delta):
	geiger_counter(delta)
	apply_gravity(delta)
	if alive:
		if velocity.x != 0:
			breathing_delay += delta

			if breathing_delay >= 10.0 and not breathing_active:
				breathing_active = true
				_play_breath()
		else:
			breathing_delay = 0.0
			breathing_active = false
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
		
	if Input.is_action_just_pressed("left") or Input.is_action_just_pressed("right"):
		$Walking.pitch_scale = randf_range(0.9, 1.1)
		$Walking.play()
	
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
		play_shot()
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
	if Input.is_action_just_pressed("shoot") and loaded_in == 0:
		$Click.play()
	
	# reload
	if Input.is_action_just_pressed("reload") and loaded_in < 8 and not reloading:
		$Reload.play()
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
	if alive:
		$Death.play()
		velocity.x = 0
		print("death")
		alive = false
		body_sprite.play("dead")
		$Head.visible = false

		await get_tree().process_frame
		var dead_head := dead_head_scene.instantiate()
		add_child(dead_head)
		dead_head.position.y -= 32
		$GPUParticles2D.emitting = true

		var random_x := randf_range(-100, 100)
		var upward := randf_range(-200, -350)

		dead_head.apply_impulse(Vector2(random_x, upward))
		
		await get_tree().create_timer(3.0, false).timeout
		$CanvasLayer2/Button.disabled = false
		
		var tween = create_tween()
		tween.tween_property($CanvasLayer/ColorRect, "color", Color(0, 0, 0, 1), 2.0)
				
		var master_idx = AudioServer.get_bus_index("Master")
		tween.parallel().tween_method(
			func(db): AudioServer.set_bus_volume_db(master_idx, db),
			0.0,    # start volume (0 dB)
			-80.0,  # silent
			2.0
		)
		
		tween.parallel().tween_property($CanvasLayer2/Button, "modulate", Color(1, 1, 1, 1), 2.0)
		
	
func get_closest_item():
	var items = get_tree().get_nodes_in_group("items")
	
	var closest_distance = INF
	
	for item in items:
		var dist = global_position.distance_to(item.global_position)
		
		if dist < closest_distance:
			closest_distance = dist
	
	return closest_distance

func geiger_counter(delta):
	wobble_time += delta
	
	var dist = get_closest_item()
	if dist == null:
		return

	dist = clamp(dist, 0, 200)
	var t = 1.0 - (dist / 200.0)

	# Needle logic (unchanged)
	var base_angle = lerp(-35.0, 35.0, t)
	var wobble_strength = lerp(1.0, 1.5, t)
	var wobble_speed = lerp(2.0, 80.0, t)
	var wobble = sin(wobble_time * wobble_speed) * wobble_strength

	beep_interval = lerp(1.0, 0.05, t) # far = slow, close = fast
	$Geiger.pitch_scale = lerp(0.9, 1.1, t)
	
	if carrying:
		base_angle = 35
		wobble = sin(wobble_time * 80) * 1.5
		beep_interval = 0.09
		$Geiger.pitch_scale = 1.1

	geiger_counter_needle.rotation_degrees = base_angle + wobble



	
	beep_timer -= delta
	if beep_timer <= 0.0:
		beep_timer = beep_interval
		
		$Geiger.play()


func _on_hitbox_body_entered(body: Node2D) -> void:
	if alive:
		death()
		
func _on_run_looped():
	if body_sprite.animation == "run":
		$Walking.pitch_scale = randf_range(0.9, 1.1)
		$Walking.play()

func play_shot():
	var p = AudioStreamPlayer2D.new()
	p.stream = $Shot.stream
	add_child(p)

	p.pitch_scale = randf_range(0.95, 1.05)
	p.play()

	p.finished.connect(_on_shot_finished.bind(p))
	
func _on_shot_finished(p):
	p.queue_free()
	
func _play_breath():
	if not breathing_active:
		return

	if not $Breathing.playing:
		$Breathing.play()

	if not $Breathing.finished.is_connected(_on_breath_finished):
		$Breathing.finished.connect(_on_breath_finished, CONNECT_ONE_SHOT)

func _on_breath_finished():
	if breathing_active and velocity.x != 0:
		_play_breath()
	else:
		breathing_active = false


func _on_button_pressed() -> void:
	var master_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_idx, 0) # back to normal

	get_tree().reload_current_scene()
	
func add_relic():
	relic_amount += 1
	if relic_amount == 3:
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 1000))
		var result = space_state.intersect_ray(query)

		if result:
			var floor_y = result.position.y
			main.add_talking(Vector2(global_position.x + 200, floor_y - 57))
		$CanvasLayer/ColorRect.color = Color(1,1,1,1)
		var tween = create_tween()
		tween.tween_property($CanvasLayer/ColorRect, "color", Color(0,0,0,0), 3.0) 
