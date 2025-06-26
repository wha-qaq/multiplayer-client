extends Node

const DOMAIN = "http://127.0.0.1:5000"
const LOGIN = DOMAIN + "/login?username=%s&password=%s" # TODO: parse it securely
const CREATE_ACCOUNT = DOMAIN + "/users?username=%s&password=%s"

const AUTH_HEADER = "jwt: %s"

const LOGIN_TOKEN_PATH = "user://login.token"
const TITLE_SCREEN = "res://Scenes/title_screen.tscn"

var request : RequestHandler = RequestHandler.new()
var auth : String = ""
var uid : int = -1

signal on_authenticated

func _put_file_token(token : String, new_uid : int) -> bool:
	var file = FileAccess.open(LOGIN_TOKEN_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"token": token, "uid": new_uid}))
	file.close()
	
	return true

func _get_file_token():
	if not FileAccess.file_exists("user://login.token"):
		return
	
	var file = FileAccess.open(LOGIN_TOKEN_PATH, FileAccess.READ)
	var contents = JSON.parse_string(file.get_as_text())
	file.close()
	
	if contents is not Dictionary or contents.get("token") is not String or contents.get("uid") is not float:
		return
	auth = contents.get("token")
	uid = int(contents.get("uid"))

func can_login() -> bool:
	if not auth or not uid:
		return false
	return true

func save_auth(token : String, new_uid : int):
	auth = token
	uid = new_uid
	_put_file_token(token, new_uid)
	on_authenticated.emit()

func get_auth_token():
	if not auth:
		return ""
	return AUTH_HEADER % auth

func get_uid():
	return uid

func request_login(username : String, password : String):
	return request.open_request(LOGIN % [username.uri_encode(), password.uri_encode()], [], HTTPClient.METHOD_POST)

func request_creation(username : String, password : String):
	return request.open_request(CREATE_ACCOUNT % [username.uri_encode(), password.uri_encode()], [], HTTPClient.METHOD_POST)

func invalidate_token():
	auth = ""
	uid = -1
	_put_file_token(auth, uid)
	
	get_tree().change_scene_to_file(TITLE_SCREEN)

func _token_recieved(response : Variant):
	if not (response is Dictionary):
		return
	
	if not response.get("token"):
		MessagingSystem.add_message("Failed to authenticate, please try again")
		return
	
	save_auth(response["token"], response["uid"])

func _ready() -> void:
	request.timeout = 6
	request.request_parsed.connect(_token_recieved)
	add_child(request)
	
	if Engine.is_editor_hint():
		_get_file_token()
