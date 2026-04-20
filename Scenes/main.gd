extends Node2D


const bullet_scene := preload("res://Scenes/bullet.tscn")


func _on_player_shoot(pos: Variant, dir: Variant) -> void:
	print(pos, dir)
	var bullet := bullet_scene.instantiate()
	$Main/Projectiles.add_child(bullet)
	bullet.setup(pos, dir)
