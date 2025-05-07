extends Node

const DOMAIN = "https://localhost:5000"
const LOGIN = DOMAIN + "/login?username=%s&password=%s"

var request : HTTPRequest
var auth : String = ""

func can_login() -> bool:
	return true

func save_token():
	pass

func request_token(username, password):
	#var error = request.request(LOGIN % [username, password], [], HTTPClient.METHOD_POST)
	request.request_completed.connect(_token_recieved)
	var error = request.request("http://example.com")
	return error

func _token_recieved(error, status, headers, d):
	if error != OK:
		return
	if error != status:
		return
	if not ("Content-Type: text/html" in headers):
		return
	print(d)

func _ready() -> void:
	request = HTTPRequest.new()
	add_child(request)
	
	print(request_token("hello", "world"))
	print(auth)
