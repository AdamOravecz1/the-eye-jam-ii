extends CanvasLayer

func _ready() -> void:

	$ColorRect.color = Color(1, 1, 1, 1)
	$AudioStreamPlayer.volume_db = -80
	var tween = create_tween()
	tween.tween_property($AudioStreamPlayer, "volume_db", -20.0, 10.0)
	await get_tree().create_timer(3.0, false).timeout
	var tween2 = create_tween()
	$Button.disabled = false
	tween2.tween_property($Button, "modulate", Color(1, 1, 1, 1,), 3.0)
	tween2.parallel().tween_property($Label, "modulate", Color(1, 1, 1, 1,), 3.0)

	

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main.tscn")
