extends Control

const DOMAIN = "http://127.0.0.1:5000"
const ROOM_ACCESS = DOMAIN + "/users/access"
const ROOM_CREATE = DOMAIN + "/rooms"
const ROOM_GET = DOMAIN + "/rooms?room_id=%s"

const ROOM_PERM = DOMAIN + "/rooms/modify?room_id=%s&allow=%s"
const ROOM_RENAME = DOMAIN + "/rooms/modify?room_id=%s&room_name=%s"
const ROOM_DEL = DOMAIN + "/rooms/modify?room_id=%s"

@onready var room_example = $RoomExample
@onready var room_details = $Scroll/Box/Vertical/RoomDetails
@onready var room_initiate = $Scroll/Box/Vertical/RoomInitiate

@onready var room_container = $Scroll/Box/Rooms/Scrolling/Margin/Container

@onready var select_prompt = $Scroll/Box/Vertical/RoomDetails/SelectPrompt
@onready var missing_rooms = $Scroll/Box/Rooms/MissingRooms
@onready var warning_notification = $Warning
@onready var fade_into = $FadeInto

@onready var room_request : RequestHandler = RequestHandler.new()
@onready var room_open : RequestHandler = RequestHandler.new()
@onready var room_get : RequestHandler = RequestHandler.new()
@onready var room_post : RequestHandler = RequestHandler.new()

var selected_room : int = -1

func change_selection(new_room : int, room_name : String):
	selected_room = new_room
	room_details.active_room_name = room_name
	
	if selected_room < 0:
		room_initiate.text = "Create Room"
		select_prompt.show()
		RoomConnector.deselect_room()
		return
	
	room_initiate.text = "Join Room"
	select_prompt.hide()
	request_get_room(new_room)

func populate_rooms(response):
	if response is not Dictionary:
		return
	
	var rooms = response.get("result")
	if rooms == null or not (rooms is Array):
		MessagingSystem.add_message("Could not find rooms")
		return
	
	for child in room_container.get_children():
		child.queue_free()
	
	missing_rooms.visible = len(rooms) == 0
	
	for room in rooms:
		var room_name = room.get("name")
		var id = room.get("id")
		if id is float:
			id = int(id)
		if (room_name is String) and (id is int):
			create_room_button(room_name, id)

func create_room_button(room_name : String, id : int):
	var clone = room_example.duplicate() as RoomButton
	room_container.add_child(clone)
	clone.display(room_name, id)
	clone.room_selected.connect(change_selection)

func reflect_added(response):
	if response is not Dictionary:
		return
	
	var id = response.get("id")
	var room_name = response.get("room_name")
	if not ((id is float) or (id is int)):
		return
	id = int(id)
	
	if not (room_name is String):
		return
	
	create_room_button(room_name, id)

func request_rooms():
	var response = await room_request.request_block_auth(ROOM_ACCESS)
	if response is not Dictionary:
		return
	
	populate_rooms(response)

func request_create_room():
	var response = await room_open.request_block_auth(ROOM_CREATE, [], HTTPClient.METHOD_PUT)
	if response is not Dictionary:
		return
	
	reflect_added(response)

func request_get_room(room_id : int):
	var response = await room_open.request_block_auth(ROOM_GET % room_id, [], HTTPClient.METHOD_GET)
	if response is not Dictionary:
		return
	
	room_details.populate_details(response)
	RoomConnector.prepare_room_by_response(room_id, response)

func request_modify_permission(username : String, new_permission : bool):
	if selected_room < 0:
		return
	
	var allow = "1" if new_permission else "0"
	var req = ROOM_PERM % [selected_room, allow.uri_encode()]
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify([username])
	
	var response = await room_post.request_block_auth(req, headers, HTTPClient.METHOD_POST, body)
	if response is not Dictionary:
		return
	
	room_details.reflect_change(response)
	room_details.clear_textbox()

func find_room_gui(room_id : int) -> RoomButton:
	for item in room_container.get_children():
		var room = item as RoomButton
		if not room:
			continue
		if room.id != room_id:
			continue
		return room
	return null

func request_delete_room():
	var ok = await warning_notification.open_room_warning(room_details.active_room_name)
	if not ok:
		return
	
	var response = await room_post.request_block_auth(ROOM_DEL % [selected_room], [], HTTPClient.METHOD_DELETE)
	if response is not Dictionary:
		return
	
	var message_count = response.get("messages_deleted") as int
	var users = response.get("users_removed") as int
	message_count = message_count if message_count else 0
	users = users if users else 0
	
	MessagingSystem.add_message("Deleted %s messages and removed %s users" % [message_count, users])
	room_details.clear_details()
	var room = find_room_gui(selected_room)
	if room:
		room.queue_free()
	change_selection(-1, "")

func request_modify_name(new_name : String):
	if selected_room < 0:
		return
	
	if new_name == "":
		await request_delete_room()
		return
	
	var req = ROOM_RENAME % [selected_room, new_name.uri_encode()]
	var ok = await room_post.request_block_auth(req, [], HTTPClient.METHOD_POST)
	if not ok:
		return
	
	room_details.active_room_name = new_name
	var room = find_room_gui(selected_room)
	if room:
		room.display(new_name, room.id)
	room_details.clear_textbox()

func try_logout():
	var ok = await warning_notification.open_logout_warning()
	if not ok:
		return
	
	PlayerAuth.logout_user()

func initiate_join_room(_socket : WebSocketPeer):
	var tween = fade_into.create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUINT)
	
	fade_into.modulate.a = 0
	fade_into.show()
	
	tween.tween_property(fade_into, "modulate:a", 1.0, 0.8)
	tween.tween_interval(0.4)
	
	await tween.finished
	get_tree().change_scene_to_file("res://Scenes/main_room.tscn")

func _ready() -> void:
	room_request.timeout = 6
	add_child(room_request)
	
	room_open.timeout = 6
	add_child(room_open)
	
	room_post.timeout = 6
	add_child(room_post)
	
	RoomConnector.on_connection.connect(initiate_join_room)
	
	room_details.change_permission.connect(request_modify_permission)
	room_details.room_change_name.connect(request_modify_name)
	
	await get_tree().process_frame
	
	request_rooms()

func refresh_rooms():
	room_details.clear_details()
	change_selection(-1, "")
	room_initiate.text = "Create Room"
	select_prompt.show()
	request_rooms()

func initiate_room() -> void:
	if selected_room > 0:
		RoomConnector.join_room()
		return
	
	request_create_room()
