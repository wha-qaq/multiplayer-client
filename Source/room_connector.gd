extends RequestHandler

const DOMAIN = "http://127.0.0.1:5000"
const JOIN_ROOM = DOMAIN + "/join?room_id=%s"

func join_room(room_id : int):
	open_request_auth(JOIN_ROOM % [room_id], [], HTTPClient.METHOD_POST)

func _ready():
	pass
