extends Control

signal received(bool)

const MESSAGE = "Delete room '%s'?\n(Cannot undo)"

func open_warning(room_name : String):
	show()
	$Panel/Message.text = MESSAGE % room_name
	var result = await received
	
	return result

func _on_pressed(ok : bool):
	received.emit(ok)
	hide()
