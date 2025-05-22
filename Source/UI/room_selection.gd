extends Control

signal pressed(id)

var id : int = -1

func on_pressed():
	pressed.emit(id)

func display(room_name : String, new_id : int):
	$Name.text = room_name
	id = new_id
	
	$Button.pressed.connect(on_pressed)
	show()
