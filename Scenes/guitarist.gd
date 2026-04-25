extends Area2D

@onready var speech_bubble: Label = $SpeechBubble/Speech
@onready var interaction_area: InteractionArea = $InteractionArea
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var main = get_tree().get_first_node_in_group("Main")

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
	
var audio_tweens = {}

func _talk():
	if iteration == 3:
		ending()
	main.delete_monsters()

	player.carrying = false

	fade_out_audio($Song)
	if current_line == 1:
		fade_in_audio($Talk)

	if not speech.has(current_line):
		return

	$SpeechBubble.visible = true
	var line = speech[current_line]
	await type_text(speech_bubble, line[0], 0.03)
	var next = line[1]

	if str(next) == "end":
		# END talking → fade IN background
		fade_in_audio($Song)
		fade_out_audio($Talk)

		$SpeechBubble.visible = false
		$InteractionArea/CollisionShape2D.set_deferred("disabled", true)
		current_line = -1
	else:
		current_line = next
		
func next():
	iteration += 1
	current_line = 1
	$InteractionArea/CollisionShape2D.set_deferred("disabled", false)
	if iteration == 1:
		speech = speech1
	elif iteration == 2:
		speech = speech2
		$AnimatedSprite2D.play("mild")
	elif iteration == 3:
		$AnimatedSprite2D.play("uber")

		
		
func fade_out_audio(audio):
	if audio_tweens.has(audio):
		audio_tweens[audio].kill()

	var tween = create_tween()
	audio_tweens[audio] = tween

	tween.tween_property(audio, "volume_db", -80, 0.5)
	tween.tween_callback(audio.stop)
	
	
func fade_in_audio(audio):
	if audio_tweens.has(audio):
		audio_tweens[audio].kill()

	audio.volume_db = -80
	audio.play()

	var tween = create_tween()
	audio_tweens[audio] = tween

	tween.tween_property(audio, "volume_db", 0, 0.5)
	
func type_text(label: Label, text: String, speed := 0.03) -> void:
	label.text = ""
	if iteration != 3:
		for i in text.length():
			label.text += text[i]
			await get_tree().create_timer(speed).timeout
		
		
func ending():
	main.ending()
	


func _on_area_entered(area: Area2D) -> void:
	main.ending2()





func _on_bullet_taker_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		$CollisionShape2D.set_deferred("disabled", true)


func _on_bullet_taker_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		$CollisionShape2D.set_deferred("disabled", false)
