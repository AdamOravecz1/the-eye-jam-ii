extends Area2D

@onready var speech_bubble: Label = $SpeechBubble/Speech
@onready var interaction_area: InteractionArea = $InteractionArea
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var main = get_tree().get_first_node_in_group("Main")

var current_line := 1
const speech0 := {
	1: ["Please...\nDon't give him the last relic...", 2],
	2: ["You don't know\nwhat he is capable of with it...", 3],
	3: ["You must stop him...", 4],
	4: ["You shoot him down...", 5],
	5: ["Please...", 5],
}


var speech = speech0


func _ready():
	if not Engine.is_editor_hint():
		interaction_area.interact = Callable(self, "_talk")
	
func _talk():

	if not speech.has(current_line):
		return
		
	if current_line == 4:
		player.ammo += 1
		player.update_ammo_count()


	var line = speech[current_line]
	await type_text(speech_bubble, line[0], 0.03)
	var next = line[1]

	if str(next) == "end":


		$SpeechBubble.visible = false
		$InteractionArea/CollisionShape2D.set_deferred("disabled", true)
		current_line = -1
	else:
		current_line = next

	
func type_text(label: Label, text: String, speed := 0.03) -> void:
	label.text = ""

	for i in text.length():
		label.text += text[i]
		await get_tree().create_timer(speed).timeout


func _on_area_entered(area: Area2D) -> void:
	$CollisionShape2D.queue_free()
	main.spawn_backup()
	$SpeechBubble.visible = false
	$AnimationPlayer.play("Death")
