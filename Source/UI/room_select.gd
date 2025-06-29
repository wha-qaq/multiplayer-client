extends Control

const DOMAIN = "http://127.0.0.1:5000"
const ROOM_ACCESS = DOMAIN + "/users/access"
const ROOM_CREATE = DOMAIN + "/rooms"
const ROOM_GET = DOMAIN + "/rooms?room_id=%s"
const ROOM_PERM = DOMAIN + "/rooms/modify?room_id=%s&allow=%s"

@onready var room_example = $RoomExample
@onready var room_details = $RoomDetails
@onready var room_initiate = $RoomInitiate

@onready var room_container = $Rooms/Scrolling/Margin/Container

@onready var select_prompt = $RoomDetails/SelectPrompt

@onready var room_request : RequestHandler = RequestHandler.new()
@onready var room_open : RequestHandler = RequestHandler.new()
@onready var room_get : RequestHandler = RequestHandler.new()
@onready var room_post : RequestHandler = RequestHandler.new()

var selected_room : int = -1

func change_selection(new_room : int):
	selected_room = new_room
	
	if selected_room < 0:
		room_initiate.text = "Create Room"
		select_prompt.show()
		return
	
	room_initiate.text = "Join Room"
	select_prompt.hide()
	request_get_room(new_room)

func populate_rooms(response):
	var rooms = response.get("result")
	if rooms == null or not (rooms is Array):
		MessagingSystem.add_message("Could not find rooms")
		return
	
	for child in room_container.get_children():
		child.queue_free()
	
	for room in rooms:
		var room_name = room.get("name")
		var id = room.get("id")
		if id is float:
			id = int(id)
		if (room_name is String) and (id is int):
			create_room_button(room_name, id)

func create_room_button(room_name : String, id : int):
	var clone = room_example.duplicate()
	room_container.add_child(clone)
	if clone.has_method("display"):
		clone.display(room_name, id)
	if clone.has_signal("pressed"):
		clone.pressed.connect(change_selection)

func reflect_added(response):
	var id = response.get("id")
	var room_name = response.get("room_name")
	if not ((id is float) or (id is int)):
		return
	id = int(id)
	
	if not (room_name is String):
		return
	
	create_room_button(room_name, id)

func request_rooms():
	return room_request.open_request_auth(ROOM_ACCESS)

func request_create_room():
	var response = await room_open.request_block_auth(ROOM_CREATE, [], HTTPClient.METHOD_PUT)
	if not response:
		return
	reflect_added(response)

func request_get_room(room_id : int):
	var response = await room_open.request_block_auth(ROOM_GET % room_id, [], HTTPClient.METHOD_GET)
	if not response:
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
	
	room_details.reflect_change(response)

func initiate_join_room(_socket : WebSocketPeer):
	get_tree().change_scene_to_file("res://Scenes/main_room.tscn")

func _ready() -> void:
	room_request.timeout = 6
	room_request.request_parsed.connect(populate_rooms)
	add_child(room_request)
	
	room_open.timeout = 6
	add_child(room_open)
	
	room_post.timeout = 6
	add_child(room_post)
	
	RoomConnector.on_connection.connect(initiate_join_room)
	
	room_details.change_permission.connect(request_modify_permission)
	
	await get_tree().process_frame
	
	request_rooms()

func refresh_rooms():
	room_details.clear_details()
	RoomConnector.deselect_room()
	room_initiate.text = "Create Room"
	select_prompt.show()
	request_rooms()

func initiate_room() -> void:
	if selected_room > 0:
		RoomConnector.join_room()
		return
	
	request_create_room()
