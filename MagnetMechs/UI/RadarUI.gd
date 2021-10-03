extends Control

export var tracking_radius: float = 25 # radius around player in meters
export var radar_radius: float = 96 # radius of sprite in pixels
onready var marker_template = $MarkerSprite

var player: Player
var rescue_pods = []
var markers = []

func _ready() -> void:
	player = get_tree().get_nodes_in_group("players")[0]
	var cargo = get_tree().get_nodes_in_group("cargo")

	for c in cargo:
		if c.type_name == "Rescue Pod":
			var marker: Sprite = marker_template.duplicate()
			marker.name = c.name
			marker.show()
			add_child(marker)
			rescue_pods.append(c)
			markers.append(marker)
			



func _process(delta: float) -> void:
	var t = player.global_transform
	
	for i in range(rescue_pods.size()):
		var pod = rescue_pods[i]
		var p = pod.global_transform.origin
		var offset = p - t.origin
		var dist = offset.length()
		
		var marker: Sprite = markers[i]
		marker.frame = 2 if pod.in_rescue_zone else 0
		if dist < tracking_radius:
			marker.frame += 1
			
		dist = clamp(dist, 0, tracking_radius)
		# Calculate marker offset and rotate to get position
		var mp = Vector2(0, (dist / tracking_radius) * radar_radius)
		var angle = Vector2(offset.x, offset.z).normalized().angle_to(Vector2(t.basis.z.x, t.basis.z.z).normalized())
		mp = mp.rotated(angle)
		marker.position = Vector2(-mp.x, mp.y) # not sure why x is negative, but whatever!
