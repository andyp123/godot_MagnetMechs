extends Control

var current_level


func _on_NextButton_pressed() -> void:
	current_level.proceed_to_next_level()
