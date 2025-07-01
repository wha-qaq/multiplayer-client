extends Control

signal received(bool)

const MESSAGE_DELETE = "Delete room '%s'?\n(Cannot undo)"
const MESSAGE_LOGOUT = "Log out?"

func open_room_warning(room_name : String):
	if visible:
		return false
	
	show()
	$Panel/Message.text = MESSAGE_DELETE % room_name
	var result = await received
	
	return result

func open_logout_warning():
	if visible:
		return false
	
	show()
	$Panel/Message.text = MESSAGE_LOGOUT
	var result = await received
	
	return result

func _on_pressed(ok : bool):
	received.emit(ok)
	hide()
