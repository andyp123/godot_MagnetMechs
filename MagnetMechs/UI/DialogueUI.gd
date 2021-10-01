extends Control

onready var portrait: Sprite = $DialogueBox/Portrait
onready var name_label: Label = $DialogueBox/NameLabel
onready var dialogue_box: RichTextLabel = $DialogueBox/DialogueLabel
onready var timer: Timer = $TextTimer

export var time_per_character: float = 0.05 # bbcode has hidden chars, so careful!
var min_dialogue_time: float = 2
var dialogue_index = 0
var dialogue = []

func set_dialogue(new_dialogue, char_name: String = "") -> void:
	dialogue_index = 0
	dialogue = new_dialogue
	dialogue_box.bbcode_text = dialogue[0]
	if char_name != "":
		name_label.text = char_name
	show()
	
	var time = max(min_dialogue_time, time_per_character * dialogue_box.bbcode_text.length())
	timer.start(time)


func queue_text() -> void:
	pass


func _on_TextTimer_timeout() -> void:
	# should advance dialogue
	dialogue_index += 1
	if dialogue_index < dialogue.size():
		dialogue_box.bbcode_text = dialogue[dialogue_index]
		var time = max(min_dialogue_time, time_per_character * dialogue_box.bbcode_text.length())
		timer.start(time)
	else:
		hide()
