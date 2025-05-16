extends Control

const DOMAIN = "http://127.0.0.1:5000"
const ROOM_ACCESS = DOMAIN + "/users/access"
const ROOM_CREATE = DOMAIN + "/rooms"
const ROOM_GET = DOMAIN + "/rooms?room_id=%s"

@onready var request : RequestHandler = RequestHandler.new()

func populate_rooms():
	pass

func request_rooms():
	return request.open_request_auth(ROOM_ACCESS)

func request_create_room():
	return request.open_request_auth(ROOM_CREATE, [], HTTPClient.METHOD_POST)

func request_get_room(room_id):
	return request.open_request_auth(ROOM_GET % room_id, [], HTTPClient.METHOD_POST)

func _ready() -> void:
	request.timeout = 3
	request.request_completed.connect(populate_rooms)
	print(request_rooms())
