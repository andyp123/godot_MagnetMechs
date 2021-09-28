extends Skeleton
class_name MechWalker

# Settings
#export var step_length: float = 1.5
export var max_step_length: float = 2.5
export var step_duration: float = 0.5
export var step_height: float = 1.5
export var leg_length: float = 6
export var foot_x_offset: float = 0.25
export var max_floor_angle: float = 60

# Components
onready var ik_left: SkeletonIK = find_node("IK_Left")
onready var ik_right: SkeletonIK = find_node("IK_Right")
# Bones
onready var body_id: int = find_bone("body")
onready var hip_l_id: int = find_bone("upper_leg_l")
onready var hip_r_id: int = find_bone("upper_leg_r")
onready var foot_l_id: int = find_bone("foot_l")
onready var foot_r_id: int = find_bone("foot_r")

# Parameters for leg animation
var current_foot: SkeletonIK
var foot_lerp_time: float = step_duration # If less than this, there will be leg weirdness on start!
var foot_start_transform: Transform
var foot_end_transform: Transform
var step_failed: bool = false


func _ready() -> void:
	max_floor_angle = sin(deg2rad(max_floor_angle))
	
	if ik_left and ik_right:
		var t: Transform = global_transform
		var b: Basis = transform.basis
		ik_left.target = Transform(b, t.origin + b.x * 2 + b.y * -1)
		ik_right.target = Transform(b, t.origin + b.x * -2 + b.y * -1)
		ik_left.start(false)
		ik_right.start(false)
		_place_feet()
		current_foot = ik_left
		foot_end_transform = ik_left.target
	else:
		print("Error: Incorrect feet setup")


func manual_update(delta: float, foot_z_offset: float = 0, update_feet: bool = true) -> void:
	if current_foot == null:
		return
	if foot_lerp_time < step_duration:
		var body_y = (global_transform * (get_bone_global_pose(hip_l_id).origin)).y
		var diff_y = body_y - foot_start_transform.origin.y
		var step_y = min(step_height, diff_y * 0.5)
		var alpha = foot_lerp_time / step_duration
		var t = foot_start_transform.interpolate_with(foot_end_transform, alpha)
		t.origin.y += sin(alpha * PI) * step_y
		current_foot.target = t
		foot_lerp_time += delta
	else:
		current_foot.target = foot_end_transform
		if update_feet:
			step_failed = !_update_feet(foot_z_offset)


# Just used on startup to make sure the feet are in the right place
func _place_feet() -> void:
	var space_state = get_world().direct_space_state
	# Left foot
	var start = global_transform * (get_bone_global_pose(hip_l_id).origin)
	var end = start - Vector3.UP * leg_length
	var hit = space_state.intersect_ray(start, end, [self], 1)
	if _is_hit_valid(hit):
		ik_left.target = _update_foot_target(ik_left, hit)
	# Right foot
	start = global_transform * (get_bone_global_pose(hip_r_id).origin)
	end = start - Vector3.UP * leg_length
	hit = space_state.intersect_ray(start, end, [self], 1)
	if _is_hit_valid(hit):
		ik_right.target = _update_foot_target(ik_right, hit)


func _update_feet(z_offset: float = 0) -> bool:
	# Update target nodes
	var space_state = get_world().direct_space_state
	# Need to clear translation of global_transform for calculating offset positions
	var t = global_transform
	t.origin = Vector3.ZERO
	# Check left foot
	var start = global_transform * (get_bone_global_pose(hip_l_id).origin)
	var offset = t * Vector3(-foot_x_offset, -leg_length, -z_offset)
	var hit_l = space_state.intersect_ray(start, start + offset, [self], 1)
	# Check right foot
	start = global_transform * (get_bone_global_pose(hip_r_id).origin)
	offset = t * Vector3(foot_x_offset, -leg_length, -z_offset)
	var hit_r = space_state.intersect_ray(start, start + offset, [self], 1)
	# Calculate distance, ignoring y
	var zero_y = Vector3(1,0,1)
	var start_l = ik_left.target.origin
	var start_r = ik_right.target.origin
	var dist_l = 0 if !_is_hit_valid(hit_l) else ((hit_l.position - start_l) * zero_y).length()
	var dist_r = 0 if !_is_hit_valid(hit_r) else ((hit_r.position - start_r) * zero_y).length()
	# Move feet if the new hit locations are far from the current target
	# Only move one at a time, and prioritize based on distance
	if !(hit_l or hit_r):
		return false
	if max(dist_l, dist_r) > max_step_length:
		foot_lerp_time = 0
		if dist_l > dist_r:
			current_foot = ik_left
			foot_start_transform = current_foot.target
			foot_end_transform = _update_foot_target(current_foot, hit_l)
		elif dist_r > max_step_length:
			current_foot = ik_right
			foot_start_transform = current_foot.target
			foot_end_transform = _update_foot_target(current_foot, hit_r)
	return true


func _is_hit_valid(hit) -> bool:
	if !hit.empty():
		var dot: float = Vector3.UP.dot(hit['normal'])
		return dot >= max_floor_angle
	return false

func _update_foot_target(ik: SkeletonIK, hit: Dictionary) -> Transform:
	var target = ik.target
	# Calculation of forward and right vector based on
	# hit normal and forward vector of the object
	var dist = hit.normal.dot(hit.position) # Calculate signed distance of plane
	var plane = Plane(hit.normal, dist)
	var front = hit.position + global_transform.basis.z
	front = plane.project(front)
	var forward: Vector3 = (front - hit.position)
	var basis: Basis
	# If we don't handle zero vectors, we get very big problems :/
	if !forward.is_equal_approx(Vector3.ZERO):
		forward = forward.normalized()
		var right: Vector3 = (hit.normal.cross(forward))
		basis = Basis(right, hit.normal, forward)
		basis = basis.rotated(right, -PI/2) # fix armature rotation
	else:
		basis = target.basis
	# Update and return target
	target.origin = hit.position
	target.basis = basis
	return target


func get_feet_aabb() -> AABB:
	var aabb: AABB = AABB()
#	aabb = AABB(global_transform * (get_bone_global_pose(foot_l_id).origin), Vector3.ZERO)
#	aabb = aabb.expand(global_transform * (get_bone_global_pose(foot_r_id).origin))
	aabb = AABB(ik_left.target.origin, Vector3.ZERO)
	aabb = aabb.expand(ik_right.target.origin)
	return aabb


