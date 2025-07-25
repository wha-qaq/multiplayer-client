extends Control

const MINIMUM_SIZE = 800

@onready var base_user = $User
@onready var base_message = $Message
@onready var spacer = $Spacer

@onready var message_log = $Panel/Scroll/Vertical
@onready var panel = $Panel

var last_id = -1

func log_user(uid : int, uname : String):
	if last_id != -1:
		var spacer_dup = spacer.duplicate()
		message_log.add_child(spacer_dup)
		spacer_dup.show()
	
	last_id = uid
	
	var user = base_user.duplicate()
	user.text = str(uname)
	message_log.add_child(user)
	user.show()

func log_message(uid : int, uname : String, content : String):
	if uid != last_id:
		log_user(uid, uname)
	
	var message = base_message.duplicate()
	message.text = str(content)
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
	get_viewport().size_changed.connect(_resize_panel)

func _resize_panel() -> void:
	if get_viewport_rect().size.x <= MINIMUM_SIZE:
		panel.anchor_left = 0
		panel.offset_left = 16
		panel.anchor_right = 0
		panel.grow_horizontal = GrowDirection.GROW_DIRECTION_END
		return
	
	panel.anchor_left = 0.2
	panel.offset_left = 0
	panel.anchor_right = 0.8
	panel.grow_horizontal = GrowDirection.GROW_DIRECTION_BOTH
