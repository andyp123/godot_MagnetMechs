extends KinematicBody

export var follow_distance_max: float = 10
export var follow_distance_min: float = 3
export var follow_distance: float = 6

# Spring settings
var use_spring: bool = false
var spring_friction: float = 10
var spring_constant: float = 40
var spring_target: Vector3 = Vector3.ZERO
var velocity: Vector3 = Vector3.ZERO

# Mouse input settings
export var capture_mouse_cursor: bool = true
export var mouse_sensitivity: Vector2 = Vector2(0.1, 0.05)
export var max_rotation_x: float = 75
var look_input: Vector2 = Vector2.ZERO
var rotation_offset: Vector2 = Vector2.ZERO

# Stick input settings
export var stick_pan_speed: float = 4

var target: Spatial = null
var is_following = true

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	max_rotation_x = deg2rad(clamp(max_rotation_x, 0, 90))
	follow_distance = clamp(follow_distance, follow_distance_min, follow_distance_max)
	
	var players = get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		target = players[0]
		print("Found Player: ", target.name)
		
		translation = target.transform.origin + target.transform.basis.z * follow_distance
	
func _process(delta: float) -> void:
	if target == null:
		return
	
	# mouse
	rotation_offset.y += look_input.x * mouse_sensitivity.x * delta
	rotation_offset.x += look_input.y * mouse_sensitivity.y * delta
	# joy
	rotation_offset.y += (Input.get_action_strength("look_right") - Input.get_action_strength("look_left")) * stick_pan_speed * delta
	rotation_offset.x += -(Input.get_action_strength("look_up") - Input.get_action_strength("look_down")) * stick_pan_speed * delta
	
	rotation_offset.y = fmod(rotation_offset.y + 2 * PI, 2 * PI)
	rotation_offset.x = clamp(rotation_offset.x, -max_rotation_x * 0.1, max_rotation_x)
	
	var follow_offset = Vector3(0, 0, follow_distance)
	follow_offset = follow_offset.rotated(Vector3.RIGHT, -rotation_offset.x)
	follow_offset = follow_offset.rotated(Vector3.UP, -rotation_offset.y)
	var target_transform = target.global_transform
	spring_target = target_transform * follow_offset
	velocity += _get_spring_force() * delta
	
	move_and_slide(velocity, Vector3.UP)
	
	look_at(target_transform.origin, Vector3.UP)
	look_input = Vector2.ZERO


func _get_spring_force() -> Vector3:
	return -spring_friction * velocity - spring_constant * (translation - spring_target)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		look_input = event.relative
	elif event is InputEventKey:
		if event.scancode == KEY_P and event.pressed and !event.echo:
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		elif event.scancode == KEY_ESCAPE:
			get_tree().quit()
	elif event is InputEventMouseButton and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event.button_index == BUTTON_WHEEL_UP: # zoom in
			follow_distance -= 1
		elif event.button_index == BUTTON_WHEEL_DOWN: # zoom out
			follow_distance += 1
		follow_distance = clamp(follow_distance, follow_distance_min, follow_distance_max)
