extends Area2D

@onready var speech_bubble: Label = $SpeechBubble/Speech
@onready var interaction_area: InteractionArea = $InteractionArea
@onready var player = get_tree().get_first_node_in_group("Player")

var iteration = 0

var current_line := 1
const speech0 := {
	1: ["Hello, Comrade.\nHere is the job description...", 2],
	2: ["You'll go into the nuclear\nfacility and gather 3 relics.", 3],
	3: ["You will recognize them by the\nradioactive decay they give off...", 4],
	4: ["When you grab one, you need to\nbring it to me immediately...", 5],
	5: ["You are not the only\none after them...", 6],
	6: ["Good luck, Comrade.", 7],
	7: ["", "end"]
}

const speech1 := {
	1: ["So far so good\nOnly 2 left...", 2],
	2: ["Haha...", 3],
	3: ["", "end"]
}
const speech2 := {
	1: ["ONLY THE LAST ONE...", 2],
	2: ["BRING IT OUT...", 3],
	3: ["HAHAHAHAHA...", 4],
	4: ["", "end"]
}

var speech = speech0


func _ready():
	if not Engine.is_editor_hint():
		interaction_area.interact = Callable(self, "_talk")
	
func _talk():
	player.carrying = false
	if not speech.has(current_line):
		return

	$SpeechBubble.visible = true
	var line = speech[current_line]

	speech_bubble.text = line[0]

	var next = line[1]


	if str(next) == "end":
		$SpeechBubble.visible = false
		$InteractionArea/CollisionShape2D.set_deferred("disabled", true)
		current_line = -1  # or reset to 1 if you want looping
	else:
		current_line = next
		
func next():
	iteration += 1
	current_line = 1
	$InteractionArea/CollisionShape2D.set_deferred("disabled", false)
	if iteration == 1:
		speech = speech1
		$AnimatedSprite2D.play("mild")
	elif iteration == 2:
		speech = speech2
		$AnimatedSprite2D.play("uber")
		
