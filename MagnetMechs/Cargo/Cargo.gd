extends RigidBody
class_name Cargo

onready var mesh = $Mesh

# Info to be displayed by cargo popup
export var type_name: String = "<Missing>"
export var weight_units: int = 1
export var expiry_time: int = -1

# Spring settings
var spring_friction: float = 4
var spring_constant: float = 400
var spring_coupling_distance: float = 2
var spring_target_offset: Vector3 = Vector3.ZERO
var spring_target
onready var inv_mass: float = 1.0 / weight_units

signal uncoupled

var velocity: Vector3 = Vector3.ZERO

func _get_spring_force() -> Vector3:
	var quat := Quat(spring_target.transform.basis.orthonormalized())
	var target: Vector3 = spring_target.translation + quat * spring_target_offset
	return -spring_friction * velocity - spring_constant * (translation - target)


func attach_to_target(target: Spatial, target_offset: Vector3 = Vector3.ZERO):
	var emit_uncoupled = (spring_target != null and target != spring_target)
	
	# remove collision layer of target from mask
	if target != null:
		add_collision_exception_with(target)
	if spring_target != null:
		remove_collision_exception_with(spring_target)
		
	spring_target = target
	spring_target_offset = target_offset
	
	var is_rigid = target == null
	if is_rigid:
		velocity = Vector3.ZERO
		mode = MODE_RIGID
	else:
		velocity = linear_velocity
		mode = MODE_KINEMATIC
	for c in get_children():
		if c is CollisionShape:
			c.disabled = !is_rigid
	can_sleep = is_rigid

	if emit_uncoupled:
		emit_signal("uncoupled", self)


func _physics_process(delta: float) -> void:	
	if spring_target != null:
		velocity += _get_spring_force() * delta * inv_mass
		translation += velocity * delta

		var a := Quat(rotation)
		var b := Quat(spring_target.rotation)
		rotation = a.slerp(b, 0.1).get_euler()
		
#		if (spring_target.translation + spring_target_offset - translation).length() > spring_coupling_distance:
#			attach_to_target(null)


func get_aabb() -> AABB:
	return mesh.get_transformed_aabb()
