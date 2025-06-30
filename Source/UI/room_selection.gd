class_name RoomButton extends Control

signal room_selected(id, name : String)

var id : int = -1

func on_pressed():
	room_selected.emit(id, $Name.text)

func display_new():
	$Button.pressed.connect(on_pressed)
	show()

func display(room_name : String, new_id : int):
	$Name.text = room_name
	if id == -1:
		display_new()
	id = new_id
