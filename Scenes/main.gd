extends Node2D

const monster_scene := preload("res://Scenes/monster.tscn")

const bullet_scene := preload("res://Scenes/bullet.tscn")


func _on_player_shoot(pos: Variant, dir: Variant) -> void:
	var bullet := bullet_scene.instantiate()
	$Main/Projectiles.add_child(bullet)
	bullet.setup(pos, dir)

func spawn_monsters(spawn_list):
	for i in spawn_list:
		var monster := monster_scene.instantiate()
		$Main/Entitis.add_child(monster)
		print($Main/SpawnPointHolder.get_child(i))
		monster.global_position = $Main/SpawnPointHolder.get_child(i).global_position
	
