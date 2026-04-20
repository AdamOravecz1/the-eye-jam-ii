extends Area2D

var direction: Vector2
var rotation_angle: float
var speed: int = 1000


func setup(pos, rot):
	position = pos 
	rotation_angle = rot
	
	direction = Vector2.RIGHT.rotated(rotation_angle)
	rotation = rotation_angle


func _process(delta):
	position += direction * speed * delta


func _on_kill_timer_timeout():
	queue_free()
