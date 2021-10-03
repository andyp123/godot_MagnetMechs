extends Spatial
class_name RescueZone

export var required_type: String = "Rescue Pod"
export var required_rescues: int = 3
export var mission_critical: bool = true
var current_rescues: int = 0

onready var detector = $Detector

signal cargo_entered
signal cargo_exited

func _ready() -> void:
	detector.connect("cargo_hovered", self, "_cargo_hover")
	detector.connect("cargo_unhovered", self, "_cargo_hover")

func _cargo_hover(cargo: Cargo, hovered: bool) -> void:
	if cargo.type_name == required_type:
		cargo.in_rescue_zone = hovered
		if hovered:
			current_rescues += 1
			emit_signal("cargo_entered", self, cargo)
		else:
			current_rescues -= 1
			emit_signal("cargo_exited", self, cargo)
	

