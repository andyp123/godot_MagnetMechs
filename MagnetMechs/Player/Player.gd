extends KinematicBody
class_name Player

# Base settings
export var max_speed: float = 6
export var turn_rate: float = deg2rad(120)
export var accel: float = 8
export var decel: float = 20
export var height_adjust_speed: float = 3

# Body height
export var body_height_min: float = 1
export var body_height_max: float = 4
var body_height: float = 2.5

# Spring settings
var use_spring: bool = false
var spring_friction: float = 5
var spring_constant: float = 40
var spring_target: Vector3 = Vector3.ZERO

onready var legs: MechWalker = $Armature/Skeleton
onready var detector: Detector = $Detector
onready var cargo_collider: CollisionShape = $CargoCollision
var max_cargo = 3
var max_weight = 3
var cargo_stack = []

# Popup UI
export (PackedScene) var cargo_ui_template
export var cargo_ui_scale: float = 3
var cargo_ui

onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") * 2
var velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	detector.connect("cargo_hovered", self, "_cargo_hover")
	detector.connect("cargo_unhovered", self, "_cargo_hover")
	cargo_ui = cargo_ui_template.instance()
	detector.add_child(cargo_ui)
	cargo_ui.translation += Vector3.UP * -1
	cargo_ui.scale = Vector3.ONE * cargo_ui_scale
	cargo_ui.hide()
	

func _cargo_hover(cargo: Cargo, hovered: bool) -> void:
	if hovered:
		cargo_ui.update_fields(cargo.type_name, cargo.weight_units)
		cargo_ui.show()
	else:
		cargo_ui.hide()
	
	
func _physics_process(delta: float) -> void:
	# Get input
	var move_input := Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	var turn_input := Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left")
	var height_input := Input.get_action_strength("raise_height") - Input.get_action_strength("lower_height")

	var stack_size = cargo_stack.size()

	# Apply rotation and movement with acceleration
	rotation.y += -turn_input * turn_rate * delta
	var forward := -transform.basis.z
	forward.y = 0
	var target_velocity := forward * move_input * max_speed
	var acceleration := accel if move_input != 0 else decel
	target_velocity.y = velocity.y
	velocity += (target_velocity - velocity) * acceleration * delta
	
	# Adjust player height
	if height_input > 0 or detector.tracked_object_count() == 0:
		body_height += height_input * height_adjust_speed * delta
		body_height = clamp(body_height, body_height_min + stack_size, body_height_max)
		
	var feet = legs.get_feet_aabb()
	var center = 0.5 * (feet.end + feet.position)
	center.y = min(feet.position.y, feet.end.y)
	spring_target = center + Vector3.UP * body_height
	velocity += _get_spring_force() * delta

	# Add gravity and calculate new position and velocity
	velocity += Vector3.UP * -gravity * delta
	velocity = move_and_slide(velocity, Vector3.UP)#, false, 4, 0.785398, false)

	# Really need to rework the legs to be less of a mess
	legs.manual_update(delta, move_input * 5)

	# Pick up/drop cargo
	if Input.is_action_just_pressed("pick_up") and cargo_stack.size() < max_cargo:
		var cargo: Cargo = detector.get_nearest_cargo(translation)
		if cargo:
			var total_weight = 0
			for c in cargo_stack:
				total_weight += c.weight_units
			if total_weight + cargo.weight_units <= max_weight:
				cargo.attach_to_target(self, Vector3(0, -(total_weight + cargo.weight_units * 0.5), -0.15))
				cargo.connect("uncoupled", self, "_on_cargo_decoupled")
				cargo_stack.append(cargo)
				_adjust_cargo_collider()
	
	if Input.is_action_just_pressed("drop"):
		var cargo: Cargo = cargo_stack.back()
		if cargo:
			cargo_stack.erase(cargo)
			_adjust_cargo_collider() # best do this before making cargo rigid again
			# This will trigger _on_cargo_decoupled
			cargo.attach_to_target(null)
			cargo.apply_central_impulse(-Vector3.UP * 2 + velocity * 0.5)


func _on_cargo_uncoupled(cargo: Cargo) -> void:
	cargo_stack.erase(cargo)
	cargo.disconnect("uncoupled", self, "_on_cargo_uncoupled")


func _adjust_cargo_collider() -> void:
	var total_weight = 0
	for c in cargo_stack:
		total_weight += c.weight_units
	var stack_size = total_weight
	cargo_collider.disabled = stack_size == 0
	
	var collider: CylinderShape = cargo_collider.shape
	collider.height = stack_size
	cargo_collider.translation = Vector3(0, -(stack_size * 0.5), 0)
	
	detector.translation.y = -stack_size - 0.5

# Helper functions
func _get_spring_force() -> Vector3:
	return -spring_friction * velocity - spring_constant * (translation - spring_target)


func _get_ground_hit() -> Dictionary:
	var state := get_world().direct_space_state
	var end := translation - Vector3.UP * (body_height + 0.25)
	return state.intersect_ray(translation, end, [self], 1)
