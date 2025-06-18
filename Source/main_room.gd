extends Node2D

const base_message = preload("res://Scenes/Objects/message.tscn")

var change_pattern = RegEx.create_from_string("^(\\d+)([/jml])(.*)$")
@onready var main_character = $MainCharacter

@onready var character_replicator = $CharacterReplicator
@onready var message_logs = $GUI/MessageLogs

func join_character(uid : int, char_position : Vector2):
	if PlayerAuth.get_uid() == uid:
		return
	
	character_replicator.spawn_character(uid, char_position)

func leave_character(uid : int):
	if PlayerAuth.get_uid() == uid:
		return
	
	character_replicator.del_character(uid)

func say_message(uid : int, str_message : String):
	if PlayerAuth.get_uid() == uid:
		var message = base_message.instantiate()
		message.say(str_message)
		main_character.add_child(message)
		return
	
	character_replicator.say_character(uid, str_message)

func move_character(uid : int, character_position : Vector2):
	if PlayerAuth.get_uid() == uid:
		return
	
	character_replicator.move_character(uid, character_position)

func handle_change(full_change : String):
	var result = change_pattern.search(full_change)
	if not result:
		print("Invalid response")
		return
	
	var uid_string = result.get_string(1)
	if not uid_string.is_valid_int():
		print("Invalid response")
		return
	
	var uid = int(uid_string)
	var change = result.get_string(2)
	var data = result.get_string(3)
	#print(PlayerAuth.get_uid(), ": ", uid, ", ", change, ", ", data)
	
	if change == "j":
		var char_position = data.split(",", true, 1)
		if char_position.size() < 2:
			return
		
		if not (char_position[0].is_valid_float() and char_position[1].is_valid_float()):
			return
		
		join_character(uid, Vector2(float(char_position[0]), float(char_position[1])))
		return
	
	if change == "l":
		leave_character(uid)
		return
	
	if change == "m":
		say_message(uid, data)
		return

func handle_move(full_move : String):
	var content = full_move.split("|")
	if content.size() < 2:
		return
	if not content[0].is_valid_int():
		return
	
	var uid = int(content[0])
	var positioning = content[1].split(",")
	if positioning.size() < 2:
		return
	if not (positioning[0].is_valid_float() and positioning[1].is_valid_float()):
		return
	
	move_character(uid, Vector2(float(positioning[0]), float(positioning[1])))

func _ready() -> void:
	RoomConnector.change_received.connect(handle_change)
	RoomConnector.move_received.connect(handle_move)
	RoomConnector.request_joined()
	
	var timer = Timer.new()
	timer.autostart = true
	timer.wait_time = 0.05
	add_child(timer)
	timer.timeout.connect(func():
		RoomConnector.move_character(main_character.global_position)
	)

func _process(_delta: float) -> void:
	if not RoomConnector.is_room_connected():
		get_tree().change_scene_to_file("res://Scenes/room_select.tscn")

func _send_message(new_text: String) -> void:
	RoomConnector.send_message(new_text)

func _exit_room():
	RoomConnector.exit_room()

func _show_logs() -> void:
	message_logs.visible = !message_logs.visible


func _on_button_pressed() -> void:
	MessagingSystem.add_message("test message")
