extends HTTPRequest

const DOMAIN = "localhost:5000"
const LOGIN = DOMAIN + "/login"

var auth : String = ""

func can_login() -> bool:
	return true

func save_token():
	pass

func get_token():
	pass
	#auth = $HTTPRequest.request("localhost:5000").send_req

func _ready() -> void:
	print(": ", request("https://example.com"))
