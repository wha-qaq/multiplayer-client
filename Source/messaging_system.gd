extends Node

signal on_message(message : String)

var messages = []

func add_message(message : String):
	if not on_message.get_connections():
		messages.append(message)
	on_message.emit(message)

func flush_messages():
	var dup = messages.duplicate()
	messages.clear()
	return dup
