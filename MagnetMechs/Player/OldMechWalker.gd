extends KinematicBody

export var move_speed: float = 4
export var turn_rate: float = 120
export var step_length: float = 2
export var step_duration: float = 0.3
export var step_height: float = 1

export var body_offset: float = 0.5
export var body_offset_max: float = 0.8
export var body_offset_min: float = -1.8

onready var skeleton: Skeleton = $Armature/Skeleton
var ik_left: SkeletonIK
var ik_right: SkeletonIK

onready var body_id: int = skeleton.find_bone("body")
onready var hip_l_id: int = skeleton.find_bone("upper_leg_l")
onready var hip_r_id: int = skeleton.find_bone("upper_leg_r")
onready var foot_l_id: int = skeleton.find_bone("foot_l")
onready var foot_t_id: int = skeleton.find_bone("foot_r")

var TIME = 0


var velocity: Vector3 = Vector3()

# Parameters for leg animation
#enum {FOOT_LEFT, FOOT_RIGHT}
var current_foot: SkeletonIK
var foot_lerp_time: float = 0
var foot_start_transform: Transform
var foot_end_transform: Transform
var step_failed: bool = false


func _ready() -> void:
	body_offset = body_offset_max
	
	turn_rate = deg2rad(turn_rate)
	foot_lerp_time = step_duration + 1
	
	ik_left = skeleton.find_node("IK_Left")
	ik_right = skeleton.find_node("IK_Right")
	if ik_left and ik_right:
		current_foot = ik_left
		ik_left.start(false)
		ik_right.start(false)
		ik_left.target.origin = translation + Vector3.FORWARD * step_length * 2
		ik_right.target.origin = translation + Vector3.FORWARD * step_length * 2
		_update_feet()
	

func _physics_process(delta: float) -> void:
	TIME += delta
	
	if Input.is_action_just_pressed("toggle_crouch"):
		body_offset = body_offset_min if body_offset > body_offset_min else body_offset_max
	
	# Simple movement
	var move_forward: float = 0
	var turn: float = 0
	move_forward = Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	turn = Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left")
	rotation.y += -turn * turn_rate * delta
	
	velocity = Vector3()
	velocity += -transform.basis.z * move_forward * move_speed
	
	
	if foot_lerp_time < step_duration:
		var alpha = foot_lerp_time / step_duration
		var t = foot_start_transform.interpolate_with(foot_end_transform, alpha)
		t.origin.y += sin(alpha * PI) * step_height
		current_foot.target = t
		foot_lerp_time += delta
	else:
		current_foot.target = foot_end_transform
		step_failed = !_update_feet(Vector3(0, 0, -move_forward * step_length))

	
	# Update body height based on foot height
	var left_pos = ik_left.target.origin
	var right_pos = ik_right.target.origin
	var center = left_pos + (right_pos - left_pos) * 0.5
	center.y = min(left_pos.y, right_pos.y)
	
	# Subtle animation
	var t = skeleton.get_bone_pose(body_id)
	t.basis = Basis(Vector3.UP, sin(TIME) * PI * 0.05)
	skeleton.set_bone_pose(body_id, t)
	
	velocity += Vector3.UP * (center.y + body_offset + sin(TIME) * 0.05 - translation.y) * 5
	
	# move and slide to have collision with stuff
#	velocity -= Vector3.UP * 9.8 * delta 
	velocity = move_and_slide(velocity, Vector3.UP, true)
	

func _update_feet(offset: Vector3 = Vector3.ZERO) -> bool:
	# Update target nodes
	var space_state = get_world().direct_space_state
	var start_l = ik_left.target.origin
	var start_r = ik_right.target.origin
	
	var start = skeleton.global_transform * (skeleton.get_bone_global_pose(hip_l_id).origin + offset)
	var end = start - Vector3.UP * 9
	var hit_l = space_state.intersect_ray(start, end, [self])
	start = skeleton.global_transform * (skeleton.get_bone_global_pose(hip_r_id).origin + offset)
	end = start - Vector3.UP * 9
	var hit_r = space_state.intersect_ray(start, end, [self])
	var zero_y = Vector3(1,0,1)
	
	var dist_l = 0 if !hit_l else ((hit_l.position - start_l) * zero_y).length()
	var dist_r = 0 if !hit_r else ((hit_r.position - start_r) * zero_y).length()
	if !(hit_l or hit_r):
		return false
	if max(dist_l, dist_r) > step_length:
		foot_lerp_time = 0
		if dist_l > dist_r:
			current_foot = ik_left
			foot_start_transform = current_foot.target
			foot_end_transform = _update_foot_target(current_foot, hit_l)
		elif dist_r > step_length:
			current_foot = ik_right
			foot_start_transform = current_foot.target
			foot_end_transform = _update_foot_target(current_foot, hit_r)
	return true

func _update_foot_target(ik: SkeletonIK, hit: Dictionary) -> Transform:
	var target = ik.target
	
	# Calculation of forward and right vector based on
	# hit normal and forward vector of the object
	var dist = hit.normal.dot(hit.position) # Calculate signed distance of plane
	var plane = Plane(hit.normal, dist)
	var front = hit.position + transform.basis.z
	front = plane.project(front)
	var forward = (front - hit.position).normalized()
	var right = hit.normal.cross(forward)

	var basis = Basis(right, hit.normal, forward)
	target.origin = hit.position
	target.basis = basis.rotated(right, -PI/2) # rotate here to fix armature issue
#	ik.target = target
	
	return target



# Not especially useful as the returned vector is based on the normal only,
# so the direction it points in changes massively based on that.
# https://math.stackexchange.com/questions/137362/how-to-find-perpendicular-vector-to-another-vector
func orthonormal(v: Vector3) -> Vector3:
	var g = -1 if v.z < 0 else 1
	var h = v.z + g
	return Vector3(g - v.x * v.x/h, -v.x * v.y/h, -v.x)
	
	
	
	


	
