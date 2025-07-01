extends Node

const LOCAL_HOST = "127.0.0.1"

const DOMAIN = "http://127.0.0.1:5000"
const DOMAIN_WS = "ws://127.0.0.1:5000"

const HOST = "127.0.0.1"
const WEBSOCKET_OK = 1000
const PORT = 5000

const JOIN_ROOM = DOMAIN_WS + "/join?room_id=%s"
const GET_ROOM = DOMAIN + "/rooms?room_id=%s"
const RENAME_SELF = DOMAIN + "/rooms/name/user?room_id=%s&username=%s"

const MESSAGE_FORMAT = "m%s"
const MOVE_FORMAT = "/%s,%s"

signal on_connection(WebSocketPeer)
signal change_received(String)
signal move_received(String)

@onready var socket = WebSocketPeer.new()
var prev_state : int = -1
var udp_peer = PacketPeerUDP.new()

var room_get_request = RequestHandler.new()
var rename_user = RequestHandler.new()

var active_room = -1
var active_characters : Array = []
var active_messages : Array = []

func is_room_connected() -> bool:
	return socket.get_ready_state() == WebSocketPeer.STATE_OPEN

func join_room() -> bool:
	if active_room < 0:
		MessagingSystem.add_message("No room selected")
		return false
	
	if socket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		MessagingSystem.add_message("Already connecting")
		return false
	
	var port = 10000
	while true:
		var result = udp_peer.bind(port, LOCAL_HOST)
		if result == OK:
			break
		
		if result != ERR_UNAVAILABLE:
			print("Error occurred while binding port: ", result)
			return false
		port = port + 1
		
	socket.handshake_headers = [PlayerAuth.get_auth_token(), "port:%s" % port]
	socket.connect_to_url(JOIN_ROOM % active_room)
	MessagingSystem.add_message("Trying to connect")
	set_process(true)
	return true

func send_message(message : String) -> bool:
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return false
	
	socket.send_text(MESSAGE_FORMAT % message)
	return true

func move_character(new_pos : Vector2) -> bool:
	udp_peer.put_packet(("%s,%s" % [new_pos.x, new_pos.y]).to_utf8_buffer())
	
	return true

func rename_self(new_name : String):
	if active_room < 0:
		return
	
	rename_user.open_request_auth(RENAME_SELF % [active_room, new_name.uri_encode()], [], HTTPClient.METHOD_POST)

func exit_room():
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return false
	
	socket.close()
	return true

func request_joined() -> bool:
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return false
	
	socket.send_text("join")
	return true

func _ready():
	udp_peer.set_dest_address(HOST, PORT)
	
	room_get_request.timeout = 5
	add_child(room_get_request)
	
	rename_user.timeout = 5
	add_child(rename_user)
	
	set_process(false)
	on_connection.connect(func(_con : WebSocketPeer):
		print("Connected!"))

func _process(_delta):
	if udp_peer.get_available_packet_count() > 0:
		var array_bytes = udp_peer.get_packet()
		var packet_string = array_bytes.get_string_from_ascii()
		move_received.emit(packet_string)
	
	socket.poll()
	
	var state = socket.get_ready_state()
	if prev_state == WebSocketPeer.STATE_CONNECTING and state == WebSocketPeer.STATE_OPEN:
		on_connection.emit(socket)
	
	prev_state = state
	
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			change_received.emit(socket.get_packet().get_string_from_utf8())
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		set_process(false)
		udp_peer.close()
		if code == WEBSOCKET_OK:
			return
		MessagingSystem.disconnect_connectors()
		MessagingSystem.add_message(reason if reason else "Server forcefully disconnected")

func prepare_room(room_id : int, characters : Array, messages : Array):
	active_room = room_id
	active_characters = characters
	active_messages = messages

func deselect_room():
	active_room = -1
	active_characters = []
	active_messages = []

func prepare_room_by_response(room_id, response):
	var characters = response.get("characters")
	var messages = response.get("messages")
	
	if not (characters is Array) or not (messages is Array):
		return
	prepare_room(room_id, characters, messages)

func reload_messages():
	var room_response = await room_get_request.request_block_auth(GET_ROOM % [active_room], [], HTTPClient.METHOD_GET)
	prepare_room_by_response(active_room, room_response)
