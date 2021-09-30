extends Area

export var char_name: String = "Dr. Professor Godot (Phd)"
export var char_icon: Texture = null
export var messages = ["I created that thing to help myself climb stairs. Maybe I got carried away."]
# If set, the dialogue will only play if the player is carrying one of these
export var required_item = ""

var activated = false

func _on_Trigger_body_entered(body: Node) -> void:
	if body is Player and !activated:
		var player: Player = body
		if required_item != "" and !player.has_cargo(required_item):
			return
		player.hud.set_dialogue(messages, char_name)
		activated = true

