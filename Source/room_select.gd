extends Control

const DOMAIN = "http://127.0.0.1:5000"
const ROOM_ACCESS = "/users/access"

@onready var request = HTTPRequest.new()

func populate_rooms():
	pass

func request_rooms():
	pass

func _ready() -> void:
	request.timeout = 3
	request.request_completed.connect(populate_rooms)
	request_rooms()
	#await get_tree().process_frame
	#get_tree().change_scene_to_file("res://Scenes/main_room.tscn")
