extends Control

@onready var base_user = $User
@onready var base_message = $Message

@onready var message_log = $Panel/Scroll/Vertical

func display_messages():
	var current_id = -1
	for message_details in RoomConnector.active_messages:
		var c_id = message_details.get("character_id", 0) as int
		if not c_id:
			continue
		
		if c_id != current_id:
			current_id = c_id
			var user = base_user.duplicate()
			var label = user.get_node("Label")
			if label and label is Label:
				label.text = str(message_details.get("name", "Unnamed User"))
			message_log.add_child(user)
			user.show()
		
		var message = base_message.duplicate()
		var label = message.get_node("Label")
		if label and label is Label:
			label.text = str(message_details.get("content", ""))
		message_log.add_child(message)
		message.show()

func _refresh_messages() -> void:
	await RoomConnector.reload_messages()
	display_messages()

func _ready() -> void:
	display_messages()
