extends Control

onready var radar_ui = $RadarUI
onready var dialogue_ui = $DialogueUI

func set_dialogue(dialogue, char_name: String = "") -> void:
	dialogue_ui.set_dialogue(dialogue, char_name)
