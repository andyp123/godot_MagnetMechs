extends Area
class_name Detector

var tracked_objects = []

signal cargo_hovered
signal cargo_unhovered

func _ready() -> void:
	self.connect("body_entered", self, "_body_entered")
	self.connect("body_exited", self, "_body_exited")


func _body_entered(body: PhysicsBody) -> void:
	if body is Cargo:
		tracked_objects.append(body)
		emit_signal("cargo_hovered", body, true)


func _body_exited(body: PhysicsBody) -> void:
	if body is Cargo:
		tracked_objects.erase(body)
		emit_signal("cargo_unhovered", body, false)


func get_nearest_cargo(to_pos: Vector3) -> Cargo:
	var dist: float = 1000
	var nearest = null
	for ob in tracked_objects:
		var d = (to_pos - ob.translation).length()
		if d < dist:
			dist = d
			nearest = ob
	
	return nearest


func tracked_object_count() -> int:
	return tracked_objects.size()


func get_tracked_object_aabb() -> AABB:
	var bounds = AABB()
	for ob in tracked_objects:
		bounds = bounds.merge(ob.get_aabb())
	return bounds
