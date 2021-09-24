extends Camera

export var capture_mouse_cursor: bool = true
export var mouse_sensitivity: float = 0.2
export var move_speed = 10
export var max_speed_multiplier = 5

var look_input: Vector2 = Vector2()
var move_input: Vector3 = Vector3()
var move_multiplier: float = 1


func _ready() -> void:
	if capture_mouse_cursor:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(delta: float) -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Look
		var amount = mouse_sensitivity * delta
		var euler = transform.basis.get_euler()
		euler.y += -look_input.x * amount
		euler.x = clamp(euler.x - look_input.y * amount, -PI*0.499, PI*0.499)
		transform.basis = Basis(euler)
		look_input = Vector2()
		# Movement
		var forward: Vector3 = -global_transform.basis.z
		var right: Vector3 = global_transform.basis.x
		var dir = (right * move_input.x  + forward * move_input.z).normalized()
		global_translate(dir * move_speed * move_multiplier * delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		look_input = event.relative
	elif event is InputEventKey:
		if event.scancode == KEY_C and event.pressed and !event.echo:
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		elif event.scancode == KEY_LEFT and !event.echo:
			move_input.x += -1 if event.pressed else 1
		elif event.scancode == KEY_RIGHT and !event.echo:
			move_input.x += 1 if event.pressed else -1
		elif event.scancode == KEY_UP and !event.echo:
			move_input.z += 1 if event.pressed else -1
		elif event.scancode == KEY_DOWN and !event.echo:
			move_input.z += -1 if event.pressed else 1
		elif event.scancode == KEY_ESCAPE:
			get_tree().quit()
	elif event is InputEventMouseButton and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event.button_index == BUTTON_WHEEL_UP:
			move_multiplier = clamp(move_multiplier + 1, 1, max_speed_multiplier)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			move_multiplier = clamp(move_multiplier - 1, 1, max_speed_multiplier)
