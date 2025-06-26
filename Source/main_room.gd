extends Node2D

const base_message = preload("res://Scenes/Objects/message.tscn")

var change_pattern = RegEx.create_from_string("^(\\d+)([/jmln])(.*)$")
@onready var main_character = $MainCharacter

@onready var character_replicator = $CharacterReplicator
@onready var message_logs = $GUI/MessageLogs
@onready var settings_menu = $GUI/SettingsMenu

var active_players : Array[Dictionary] = []

func get_player_name(uid : int) -> String:
	for player in active_players:
		if player.get("uid") == uid:
			return player.get("uname", "Unnamed User")
	
	return "Unnamed User"

func change_character_name(uid : int, player_name : String):
	active_players.append({"uid": uid, "uname": player_name})
	
	if uid == PlayerAuth.get_uid():
		main_character.name_character(player_name)
		settings_menu.load_settings(player_name)
		return
	
	character_replicator.name_character(uid, player_name.uri_encode())

func join_character(uid : int, player_name : String, char_position : Vector2):
	if PlayerAuth.get_uid() == uid:
		return
	
	character_replicator.spawn_character(uid, player_name, char_position)
	active_players.append({"uid": uid, "uname": player_name})

func leave_character(uid : int):
	if PlayerAuth.get_uid() == uid:
		return
	
	character_replicator.del_character(uid)
	
	for idx in range(len(active_players)):
		var p_uid = active_players[idx].get("uid")
		if p_uid == uid:
			active_players.remove_at(idx)
			return

func say_message(uid : int, str_message : String):
	message_logs.log_message(uid, get_player_name(uid), str_message)
	
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
	
	if change == "n":
		change_character_name(uid, data)
		return
	
	if change == "j":
		var char_details = data.split(",", true, 2)
		print(char_details)
		if char_details.size() < 3:
			return
		
		if not (char_details[1].is_valid_float() and char_details[2].is_valid_float()):
			return
		
		join_character(uid, str(char_details[0]), Vector2(float(char_details[0]), float(char_details[1])))
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

func _toggle_user_movement(disable : bool) -> void:
	main_character.can_move = not disable

func _toggle_settings() -> void:
	settings_menu.visible = !settings_menu.visible
