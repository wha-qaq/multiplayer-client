extends Control

func _unhandled_input(event):
	if not (event is InputEventAction):
		return
	grab_focus()


func _on_mouse_entered() -> void:
	print("a")
