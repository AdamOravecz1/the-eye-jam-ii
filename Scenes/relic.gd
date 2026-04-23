extends Sprite2D

@onready var interaction_area: InteractionArea = $InteractionArea

func _ready():
	if not Engine.is_editor_hint():
		interaction_area.interact = Callable(self, "_pickup")
	
func _pickup():
	print("fisbfruvebd")
