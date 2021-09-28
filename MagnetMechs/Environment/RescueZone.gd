extends Spatial

export var required_rescues: int = 3
var current_rescues: int = 0

onready var detector = $Detector

func _ready() -> void:
	detector.connect("cargo_hovered", self, "_cargo_hover")
	detector.connect("cargo_unhovered", self, "_cargo_hover")
	
func _cargo_hover(cargo: Cargo, hovered: bool) -> void:
	if cargo.type_name == "Rescue Pod":
		if hovered:
			current_rescues += 1
			if current_rescues >= required_rescues:
				print("YEEEEEAAASS! I CAN FEEL MY POWER SURGING!")
			else:
				print("YES! ANOTHER VICTIM TO THE SLAUGHTER! BRING ME MORE AND YOU WILL BE REWARDED!")
		else:
			current_rescues -= 1
			print("YOU DARE STEAL FROM THE ALL POWERFUL MHATOMBATHUMBYWUMP!?")
	

