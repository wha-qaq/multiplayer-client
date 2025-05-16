extends Control

const DOMAIN = "http://127.0.0.1:5000"
const ROOM_ACCESS = DOMAIN + "/users/access"
const ROOM_CREATE = DOMAIN + "/rooms"
const ROOM_GET = DOMAIN + "/rooms?room_id=%s"

@onready var room_request : RequestHandler = RequestHandler.new()
@onready var room_create : RequestHandler = RequestHandler.new()
@onready var room_get : RequestHandler = RequestHandler.new()

func populate_rooms(response):
	var rooms = response.get("result")
	if rooms == null or not (rooms is Array):
		MessagingSystem.add_message("Could not find rooms")
		return
	
	print("To show: ", rooms)

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
	
	await get_tree().process_frame
	
	print(request_rooms())
