extends Sprite2D

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var guitar = get_tree().get_first_node_in_group("Guitar")
@onready var main = get_tree().get_first_node_in_group("Main")

func _ready():
	add_to_group("items")
	if not Engine.is_editor_hint():
		interaction_area.interact = Callable(self, "_pickup")
		
func _process(delta: float) -> void:
	if player.carrying:
		$InteractionArea.monitoring = false
	else: 
		$InteractionArea.monitoring = true
		
	
func _pickup():
	if not player.carrying:

		if frame == 0:
			main.spawn_monsters([9, 1, 2])
		if frame == 1:
			main.spawn_monsters([1, 2, 3, 8])
		if frame == 2:
			main.spawn_monsters([7, 8, 5])
		player.carrying = true
		player.add_relic()
		guitar.next()
		await get_tree().process_frame
		queue_free()
