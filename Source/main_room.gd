extends Node2D

const base_message = preload("res://Scenes/Objects/message.tscn")

var change_pattern = RegEx.create_from_string("^(\\d+)([/jml])(.*)$")
@onready var main_character = $MainCharacter

func join_character(uid : int, char_position : Vector2):
	if PlayerAuth.get_uid() == uid:
		return
	
	$CharacterReplicator.spawn_character(uid, char_position)

func leave_character(uid : int):
	if PlayerAuth.get_uid() == uid:
		return
	
	$CharacterReplicator.del_character(uid)

func say_message(uid : int, str_message : String):
	if PlayerAuth.get_uid() == uid:
		var message = base_message.instantiate()
		message.say(str_message)
		main_character.add_child(message)
		return
	
	$CharacterReplicator.say_character(uid, str_message)

func move_character(uid : int, character_position : Vector2):
	if PlayerAuth.get_uid() == uid:
		return
	
	$CharacterReplicator.move_character(uid, character_position)

func handle_change(full_change : String):
	var result = change_pattern.search(full_change)
	if not result:
		print("Invalid response")
		return
	
	var uid = int(result.get_string(1))
	var change = result.get_string(2)
	var data = result.get_string(3)
	#print(PlayerAuth.get_uid(), ": ", uid, ", ", change, ", ", data)
	
	if change == "j":
		var char_position = data.split(",", true, 1)
		if char_position.size() < 2:
			return
		
		join_character(uid, Vector2(float(char_position[0]), float(char_position[1])))
		return
	
	if change == "l":
		leave_character(uid)
		return
	
	if change == "m":
		say_message(uid, data)
		return
	
	if change == "/":
		var char_position = data.split(",", true, 1)
		if char_position.size() < 2:
			return
		
		move_character(uid, Vector2(float(char_position[0]), float(char_position[1])))
		return

func _ready() -> void:
	RoomConnector.change_received.connect(handle_change)
	RoomConnector.request_joined()
	
	var timer = Timer.new()
	timer.autostart = true
	timer.wait_time = 0.2
	add_child(timer)
	timer.timeout.connect(func():
		RoomConnector.move_character(main_character.global_position)
	)

func _process(_delta: float) -> void:
	if not RoomConnector.is_room_connected():
		get_tree().change_scene_to_file("res://Scenes/main_room.tscn")

func _send_message(new_text: String) -> void:
	RoomConnector.send_message(new_text)
