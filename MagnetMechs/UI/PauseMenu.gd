extends Control

var current_level # should be type Level

onready var menu_items = $MenuBackground
onready var help_panel = $HelpPanel

func _ready() -> void:
	pass


func _on_QuitButton_pressed() -> void:
	get_tree().quit()


func _on_ReturnToTitleButton_pressed() -> void:
	current_level.return_to_title()


func _on_RestartButton_pressed() -> void:
	current_level.restart_level()


func _on_HelpButton_pressed() -> void:
	menu_items.hide()
	help_panel.show()


func _on_ResumeButton_pressed() -> void:
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_ReturnButton_pressed() -> void:
	help_panel.hide()
	menu_items.show()


func _on_PauseMenu_visibility_changed() -> void:
	get_tree().paused = visible
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_PauseMenu_tree_exiting() -> void:
	get_tree().paused = false


func _on_MouseSensitivitySlider_value_changed(value: float) -> void:
	Settings.mouse_sensitivity = value


func _on_InvertXToggle_toggled(button_pressed: bool) -> void:
	Settings.mouse_invert_x = button_pressed


func _on_InvertYToggle_toggled(button_pressed: bool) -> void:
	Settings.mouse_invert_y = button_pressed
