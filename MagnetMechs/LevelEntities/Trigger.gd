extends Area

export var char_name: String = "Dr. Professor Godot (Phd)"
export var char_icon: Texture = null
export var messages = ["I created that thing to help myself climb stairs. Maybe I got carried away."]

var activated = false

func _on_Trigger_body_entered(body: Node) -> void:
	if body is Player and !activated:
		var player: Player = body
		print(player.hud)
		player.hud.set_dialogue(messages, char_name)
		activated = true

