extends Control

onready var radar_ui = $RadarUI
onready var dialogue_ui = $DialogueUI
onready var rescue_label = $RescueCount/RescueCountLabel

func set_dialogue(dialogue, char_name: String = "") -> void:
	dialogue_ui.set_dialogue(dialogue, char_name)
	
func set_rescue_count(found: int, total: int) -> void:
	var text = "%d/%d" % [found, total]
	rescue_label.text = text
