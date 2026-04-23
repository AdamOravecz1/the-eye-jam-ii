extends Sprite2D

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var guitar = get_tree().get_first_node_in_group("Guitar")

func _ready():
	add_to_group("items")
	if not Engine.is_editor_hint():
		interaction_area.interact = Callable(self, "_pickup")
	
func _pickup():
	if not player.carrying:
		player.carrying = true
		guitar.next()
		queue_free()
