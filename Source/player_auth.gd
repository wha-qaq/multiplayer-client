extends Node

const DOMAIN = "http://127.0.0.1:5000"
const LOGIN = DOMAIN + "/login?username=%s&password=%s" # TODO: parse it securely
const CREATE_ACCOUNT = DOMAIN + "/users?username=%s&password=%s"

const AUTH_HEADER = "jwt: %s"

var request : HTTPRequest = HTTPRequest.new()
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

func request_login(username, password):
	if request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		MessagingSystem.add_message("Already logging in... Please wait")
		return
	
	var error = request.request(LOGIN % [username, password], [], HTTPClient.METHOD_POST)
	return error

func request_creation(username, password):
	if request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		MessagingSystem.add_message("Already creating account... Please wait")
		return
	
	var error = request.request(CREATE_ACCOUNT % [username, password], [], HTTPClient.METHOD_POST)
	return error

func _token_recieved(result, response_code, headers, body : PackedByteArray):
	if result != OK:
		return
	var json = JSON.new()
	var err = json.parse(body.get_string_from_utf8())
	if err:
		MessagingSystem.add_message("Could not interpret server's response, your app may be outdated")
		return
	var response = json.get_data()
	if not (response is Dictionary):
		MessagingSystem.add_message("Could not interpret server's response, your app may be outdated")
		return
	if response_code != HTTPClient.RESPONSE_OK:
		MessagingSystem.add_message("Error occurred: " + str(response.get("error")))
		return
	if not response.get("token"):
		MessagingSystem.add_message("Failed to authenticate, please try again")
		return
	save_token(response["token"])

func _ready() -> void:
	request.timeout = 3
	request.request_completed.connect(_token_recieved)
	add_child(request)
