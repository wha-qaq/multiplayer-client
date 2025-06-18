extends Control

@onready var base_user = $User
@onready var base_message = $Message

@onready var message_log = $Panel/Scroll/Vertical

var last_id = -1

func log_message(uid : int, uname : String, content : String):
	if uid != last_id:
		last_id = uid
		var user = base_user.duplicate()
		var label = user.get_node("Label")
		if label and label is Label:
			label.text = str(uname)
		message_log.add_child(user)
		user.show()
	
	var message = base_message.duplicate()
	var label = message.get_node("Label")
	if label and label is Label:
		label.text = str(content)
	message_log.add_child(message)
	message.show()

func display_messages():
	for child in message_log.get_children():
		child.queue_free()
	last_id = -1
	
	for message_details in RoomConnector.active_messages:
		var c_id = message_details.get("character_id", 0) as int
		if not c_id:
			continue
		
		log_message(c_id, message_details.get("name", "Unnamed User"), message_details.get("content", ""))

func _refresh_messages() -> void:
	await RoomConnector.reload_messages()
	display_messages()

func _ready() -> void:
	display_messages()
