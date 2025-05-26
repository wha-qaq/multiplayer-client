extends Node2D

const base_message = preload("res://Scenes/Objects/message.tscn")

var change_pattern = RegEx.create_from_string("^(\\d+)([/jml])(.*)$")

func join_character(uid : int):
	if PlayerAuth.get_uid() == uid:
		return
	
	$CharacterReplicator.spawn_character(uid)

func say_message(uid : int, str_message : String):
	if PlayerAuth.get_uid() == uid:
		var message = base_message.instantiate()
		message.say(str_message)
		$MainCharacter.add_child(message)
		return
	
	$CharacterReplicator.say_character(uid, str_message)

func handle_change(full_change : String):
	var result = change_pattern.search(full_change)
	if not result:
		print("Invalid response")
		return
	
	var uid = int(result.get_string(1))
	var change = result.get_string(2)
	var data = result.get_string(3)
	print(uid, ", ", change, ", ", data)
	
	if change == "j":
		join_character(uid)
	
	if change == "m":
		say_message(uid, data)

func _ready() -> void:
	RoomConnector.change_received.connect(handle_change)
	
	var timer = Timer.new()
	timer.autostart = true ## TODO: FIX
	timer.start()
	add_child(timer)
	timer.timeout.connect(func():
		timer.time_left = 0.5
		print("a")
		RoomConnector.move_character($MainCharacter.global_position)
	)

func _process(_delta: float) -> void:
	if not RoomConnector.is_room_connected():
		get_tree().change_scene_to_file("res://Scenes/main_room.tscn")

func _send_message(new_text: String) -> void:
	RoomConnector.send_message(new_text)
