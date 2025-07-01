class_name RequestHandler
extends HTTPRequest

signal request_parsed
signal activated(bool)

func open_request_auth(url : String, custom_headers : PackedStringArray = PackedStringArray([]), method : HTTPClient.Method = HTTPClient.METHOD_GET, request_data : String = ""):
	var headers = custom_headers.duplicate()
	headers.append(PlayerAuth.get_auth_token())
	return open_request(url, headers, method, request_data)

func open_request(url : String, custom_headers : PackedStringArray = PackedStringArray([]), method : HTTPClient.Method = HTTPClient.METHOD_GET, request_data : String = ""):
	if get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		MessagingSystem.add_message("Please wait...")
		return ERR_ALREADY_IN_USE
	activated.emit(true)
	return request(url, custom_headers, method, request_data)

func request_block(url : String, custom_headers : PackedStringArray = PackedStringArray([]), method : HTTPClient.Method = HTTPClient.METHOD_GET, request_data : String = ""):
	var requesting = open_request(url, custom_headers, method, request_data)
	if requesting != OK:
		return
	
	var response = await request_parsed
	return response

func request_block_auth(url : String, custom_headers : PackedStringArray = PackedStringArray([]), method : HTTPClient.Method = HTTPClient.METHOD_GET, request_data : String = ""):
	var requesting = open_request_auth(url, custom_headers, method, request_data)
	if requesting != OK:
		return
	
	var response = await request_parsed
	return response

func parse_request(result : HTTPRequest.Result, response_code : int, _headers : PackedStringArray, body : PackedByteArray) -> Variant:
	activated.emit(false)
	if result != RESULT_SUCCESS:
		MessagingSystem.add_message("Unable to connect to server at this time")
		request_parsed.emit(null)
		return
	
	if response_code == HTTPClient.RESPONSE_UNAUTHORIZED:
		MessagingSystem.add_message("Please login again")
		request_parsed.emit(null)
		return
	
	if response_code == HTTPClient.RESPONSE_INTERNAL_SERVER_ERROR:
		MessagingSystem.add_message("Server encountered an error")
		request_parsed.emit(null)
		return
	
	var response = JSON.parse_string(body.get_string_from_utf8())
	if not response:
		if response_code == HTTPClient.RESPONSE_NOT_FOUND:
			MessagingSystem.add_message("Action could not occur")
			request_parsed.emit(null)
			return
		
		if response_code != HTTPClient.RESPONSE_OK:
			MessagingSystem.add_message("Could not interpret response, error code: " + str(response_code))
			request_parsed.emit(null)
			return
		
		MessagingSystem.add_message("Could not interpret server's response, your app may be outdated")
		request_parsed.emit(null)
		return
	
	if not (response is Dictionary):
		MessagingSystem.add_message("Could not interpret server's response, your app may be outdated")
		request_parsed.emit(null)
		return
	
	if response_code < 200 or response_code >= 300:
		MessagingSystem.add_message("Error occurred: " + str(response.get("error")))
		request_parsed.emit(null)
		return
	
	request_parsed.emit(response)
	return response

func _ready():
	request_completed.connect(parse_request)
