extends Node

const DOMAIN = "http://127.0.0.1:5000"
const LOGIN = DOMAIN + "/login?username=%s&password=%s" # TODO: parse it securely
const CREATE_ACCOUNT = DOMAIN + "/users?username=%s&password=%s"

const AUTH_HEADER = "jwt: %s"

var request : RequestHandler = RequestHandler.new()
var auth : String = ""
var room_id : int = -1

signal on_authenticated

func can_login() -> bool:
	if not auth:
		return false
	return true

func save_token(token : String):
	auth = token
	# TODO: Saving token
	on_authenticated.emit()

func get_auth_token():
	if not auth:
		return ""
	return AUTH_HEADER % auth

func request_login(username, password):
	return request.open_request(LOGIN % [username, password], [], HTTPClient.METHOD_POST)

func request_creation(username, password):
	return request.open_request(CREATE_ACCOUNT % [username, password], [], HTTPClient.METHOD_POST)

func _token_recieved(response : Variant):
	if not (response is Dictionary):
		return
	
	if not response.get("token"):
		MessagingSystem.add_message("Failed to authenticate, please try again")
		return
	
	save_token(response["token"])

func _ready() -> void:
	request.timeout = 3
	request.request_parsed.connect(_token_recieved)
	add_child(request)
