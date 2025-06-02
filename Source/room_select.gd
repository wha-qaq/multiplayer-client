extends Control

const DOMAIN = "http://127.0.0.1:5000"
const ROOM_ACCESS = DOMAIN + "/users/access"
const ROOM_CREATE = DOMAIN + "/rooms"
const ROOM_GET = DOMAIN + "/rooms?room_id=%s"

@onready var room_example = $RoomExample

@onready var room_request : RequestHandler = RequestHandler.new()
@onready var room_create : RequestHandler = RequestHandler.new()
@onready var room_get : RequestHandler = RequestHandler.new()

var selected_room : int = -1

func change_selection(new_room : int):
	selected_room = new_room
	
	if selected_room < 0:
		$RoomInitiate.text = "Create Room"
		return
	$RoomInitiate.text = "Join Room"

func populate_rooms(response):
	var rooms = response.get("result")
	if rooms == null or not (rooms is Array):
		MessagingSystem.add_message("Could not find rooms")
		return
	
	for room in rooms:
		var room_name = room.get("name")
		var id = room.get("id")
		if id is float:
			id = int(id)
		if (room_name is String) and (id is int):
			create_room_button(room_name, id)

func create_room_button(room_name : String, id : int):
	var clone = room_example.duplicate()
	$Rooms/Scrolling/Margin/Container.add_child(clone)
	if clone.has_method("display"):
		clone.display(room_name, id)
	if clone.has_signal("pressed"):
		clone.pressed.connect(change_selection)

func reflect_added(response):
	print("To add to list: ", response)
	return

func display_room(response):
	print("To display: ", response)
	
	return

func request_rooms():
	return room_request.open_request_auth(ROOM_ACCESS)

func request_create_room():
	return room_create.open_request_auth(ROOM_CREATE, [], HTTPClient.METHOD_POST)

func request_get_room(room_id):
	return room_get.open_request_auth(ROOM_GET % room_id, [], HTTPClient.METHOD_POST)

func request_join_room(room_id : int):
	RoomConnector.join_room(room_id)

func initiate_join_room(_socket : WebSocketPeer):
	get_tree().change_scene_to_file("res://Scenes/main_room.tscn")

func _ready() -> void:
	room_request.timeout = 3
	room_request.request_parsed.connect(populate_rooms)
	add_child(room_request)
	
	room_create.timeout = 3
	room_create.request_parsed.connect(reflect_added)
	add_child(room_create)
	
	room_get.timeout = 3
	room_get.request_parsed.connect(display_room)
	add_child(room_get)
	
	RoomConnector.on_connection.connect(initiate_join_room)
	
	await get_tree().process_frame
	
	print(request_rooms())


func initiate_room() -> void:
	if selected_room < 0:
		request_create_room()
		return
	
	request_join_room(selected_room)
