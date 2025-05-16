class_name RequestHandler
extends HTTPRequest

signal request_parsed
signal activated(bool)

func open_request_auth(url : String, custom_headers : PackedStringArray = PackedStringArray([]), method : HTTPClient.Method = HTTPClient.METHOD_GET, request_body : String = "") -> Error:
	var headers = custom_headers.duplicate()
	headers.append(PlayerAuth.get_auth_token())
	return open_request(url, headers, method, request_body)

func open_request(url : String, custom_headers : PackedStringArray = PackedStringArray([]), method : HTTPClient.Method = HTTPClient.METHOD_GET, request_data : String = ""):
	if get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		MessagingSystem.add_message("Please wait...")
		return ERR_ALREADY_IN_USE
	activated.emit(true)
	return request(url, custom_headers, method, request_data)

func parse_request(result : HTTPRequest.Result, response_code : int, _headers : PackedStringArray, body : PackedByteArray) -> Variant:
	activated.emit(false)
	if result != RESULT_SUCCESS:
		print(result)
		MessagingSystem.add_message("Unable to connect to server at this time")
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
	
	request_parsed.emit(response)
	return response

func _ready():
	request_completed.connect(parse_request)
