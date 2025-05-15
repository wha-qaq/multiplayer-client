extends Node

const DOMAIN = "http://127.0.0.1:5000"
const LOGIN = DOMAIN + "/login?username=%s&password=%s" # TODO: parse it securely

var request : HTTPRequest = HTTPRequest.new()
var auth : String = ""

func can_login() -> bool:
	if not auth:
		return false
	return true

func save_token(token : String):
	auth = token
	# TODO: Saving token

func request_login(username, password):
	request.request_completed.connect(_token_recieved)
	var error = request.request(LOGIN % [username, password], [], HTTPClient.METHOD_POST)
	#var error = request.request("https://example.com/")
	return error

func _token_recieved(result, response_code, headers, body : PackedByteArray):
	if result != OK:
		return
	var json = JSON.new()
	var err = json.parse(body.get_string_from_utf8())
	if err:
		print("Invalid response")
		return
	var response = json.get_data()
	if not (response is Dictionary):
		print("Invalid response")
		return
	if response_code != HTTPClient.RESPONSE_OK:
		print("Error given: ", response.get("error"))
		return
	if not response.get("token"):
		print("Token not found")
		return
	save_token(response["token"])

func _ready() -> void:
	add_child(request)
	
	request_login("hello", "world") # NOTE: Test code, delete later
