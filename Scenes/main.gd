extends Node2D

var running_timer = false

const monster_scene := preload("res://Scenes/monster.tscn")
const talking_monster_scene := preload("res://Scenes/talking_monster.tscn")
const bullet_scene := preload("res://Scenes/bullet.tscn")

var spawn_pos = []

func _process(delta: float) -> void:
	var should_run = $Main/Entitis/Player.global_position.x > 1100 and not $Main/Entitis/Player.carrying


	if should_run and not running_timer:
		running_timer = true
		$Timer.start()

	elif not should_run and running_timer:
		running_timer = false
		$Timer.stop()


func _on_player_shoot(pos: Variant, dir: Variant) -> void:
	var bullet := bullet_scene.instantiate()
	$Main/Projectiles.add_child(bullet)
	bullet.setup(pos, dir)

func spawn_monsters(spawn_list):
	spawn_pos = spawn_list
	if $Main/Entitis/Player.relic_amount != 2:
		for i in spawn_list:
			var monster := monster_scene.instantiate()
			$Main/Monsters.add_child(monster)
			print($Main/SpawnPointHolder.get_child(i))
			monster.global_position = $Main/SpawnPointHolder.get_child(i).global_position
	
func delete_monsters():
	for i in $Main/Monsters.get_children():
		i.queue_free()
		

func _on_timer_timeout() -> void:
	var sounds = $Sounds.get_children()
	if sounds.is_empty():
		return

	var sound = sounds[randi() % sounds.size()]

	# play sound
	sound.play()

	# wait until it finishes
	await sound.finished

	# set random timer duration (5–15 sec)
	$Timer.wait_time = randf_range(5.0, 15.0)

	if $Main/Entitis/Player.global_position.x > 1100 and not $Main/Entitis/Player.carrying:
		$Timer.start()
	
func ending():
	call_deferred("_go_ending")

func ending2():
	call_deferred("_go_ending2")


func _go_ending():
	get_tree().change_scene_to_file("res://Scenes/ending_one.tscn")

func _go_ending2():
	get_tree().change_scene_to_file("res://Scenes/ending_2.tscn")
	
func add_talking(pos):
	var talking_monster := talking_monster_scene.instantiate()
	$BG.add_child(talking_monster)
	talking_monster.global_position = pos
	
func spawn_backup():
	call_deferred("_spawn_backup")

func _spawn_backup():
	for i in spawn_pos:
		var monster := monster_scene.instantiate()
		$Main/Monsters.add_child(monster)
		monster.global_position = $Main/SpawnPointHolder.get_child(i).global_position
