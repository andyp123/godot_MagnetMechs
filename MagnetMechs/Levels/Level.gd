extends Spatial

# Connected stages
export var next_scene: String
# Menus
export (PackedScene) var pause_menu_template
export (PackedScene) var level_clear_ui_template

# Spawned by level
var pause_menu
var level_clear_ui
var follow_camera
var player

# Mission Objectives
var rescue_zones
var required_rescues = 0
var current_rescues = 0


func restart_level() -> void:
	get_tree().reload_current_scene()

func return_to_title() -> void:
	get_tree().change_scene("res://Title/Title.tscn")

func proceed_to_next_level() -> void:
	get_tree().change_scene(next_scene)

func _ready() -> void:
	rescue_zones = get_tree().get_nodes_in_group("rescue_zones")
	for zone in rescue_zones:
		if zone.mission_critical:
			required_rescues += zone.required_rescues
			zone.connect("cargo_entered", self, "_on_rescue")
			zone.connect("cargo_exited", self, "_on_unrescue")
	# Pause menu
	pause_menu = pause_menu_template.instance()
	pause_menu.current_level = self
	pause_menu.hide()
	add_child(pause_menu)
	# Level clear UI
	level_clear_ui = level_clear_ui_template.instance()
	level_clear_ui.current_level = self
	level_clear_ui.hide()
	add_child(level_clear_ui)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_rescue(rescue_zone: RescueZone, cargo: Cargo) -> void:
	current_rescues += 1
	if current_rescues >= required_rescues:
		pause_menu.hide() # just in case
		level_clear_ui.show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_unrescue(rescue_zone: RescueZone, cargo: Cargo) -> void:
	current_rescues -= 1


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE and event.pressed and !event.echo:
			if pause_menu.visible:
				pause_menu.hide()
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				pause_menu.show()
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)



