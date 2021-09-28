extends Spatial

onready var type_label = $Viewport/NinePatchRect/VBoxContainer/Type
onready var weight_label = $Viewport/NinePatchRect/VBoxContainer/Weight/value

func update_fields(cargo_type: String, weight: int) -> void:
	type_label.text = cargo_type
	weight_label.text = str(weight) + "t"
