extends Spatial

#onready var default_level = preload(export (PackedScene))
export (PackedScene) var default_level = preload("res://Default.tscn")
onready var logo = $Logo
onready var mech_legs = $PlayerMech/Armature/Skeleton

# Array of dictionaries
var letters = {}
var letter_mode: int = RigidBody.MODE_KINEMATIC
var letter_rotation_speed: float = 180
var spring_friction: float = 10
var spring_constant: float = 60

func _ready() -> void:
	randomize()
	letter_rotation_speed = deg2rad(letter_rotation_speed)
	
	# Replace static bodies with rigid bodies
	var i: int = logo.get_child_count() - 1
	var children = logo.get_children()
	while i >= 0:
		var node: Spatial = children[i]
		var sb: StaticBody = node.get_node("StaticBody")
		var sb_children = sb.get_children()
		var rb: RigidBody = RigidBody.new()
		rb.name = "RB_" + node.name
		rb.global_transform = node.global_transform
		rb.mode = letter_mode
		for c in sb_children:
			sb.remove_child(c)
			rb.add_child(c)
		logo.remove_child(node)
		rb.add_child(node)
		node.transform = Transform()
		logo.add_child(rb)
		sb.queue_free()
		letters[node.name] = {'body': rb, 'transform': rb.transform, 'velocity': Vector3.ZERO}
		i -= 1


func toggle_letter_mode() -> void:
	if letter_mode == RigidBody.MODE_RIGID:
		letter_mode = RigidBody.MODE_KINEMATIC
	else:
		letter_mode = RigidBody.MODE_RIGID
		
	for letter in letters.values():
		letter['body'].mode = letter_mode
		if letter_mode == RigidBody.MODE_RIGID:
			var impulse = Vector3(rand_range(-1,1) * 4, rand_range(-1,1), rand_range(-1,1) * 2)
			letter['body'].apply_central_impulse(impulse)
		else:
			letter['velocity'] = Vector3.ZERO


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_select"):
		toggle_letter_mode()
	
	if letter_mode == RigidBody.MODE_KINEMATIC:
		for letter in letters.values():
			var body: RigidBody = letter['body']
			var velocity: Vector3 = letter['velocity']
			var target: Transform = letter['transform']
			# Update velocity and position
			var force: Vector3 = Vector3.ZERO
			force = -spring_friction * velocity - spring_constant * (body.translation - target.origin)
			velocity += force * delta
			body.translation += velocity * delta
			letter['velocity'] = velocity
			# Lerp rotation
			var quat_body := Quat(body.transform.basis)
			var quat_target := Quat(target.basis)
			quat_body = quat_body.slerp(quat_target, letter_rotation_speed * delta)
			body.transform.basis = Basis(quat_body)
			
	mech_legs.manual_update(delta)



func _on_QuitButton_pressed() -> void:
	get_tree().quit()


func _on_StartButton_pressed() -> void:
	get_tree().change_scene_to(default_level)


func _on_SpecialButton_pressed() -> void:
	toggle_letter_mode()
