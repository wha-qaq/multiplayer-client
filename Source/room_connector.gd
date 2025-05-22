extends Node

const DOMAIN_WS = "ws://127.0.0.1:5000"
const JOIN_ROOM = DOMAIN_WS + "/join?room_id=%s"

signal on_connection(WebSocketPeer)
signal change_received(String)

@onready var socket = WebSocketPeer.new()
var prev_state : int = -1

func join_room(room_id : int):
	if socket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		return
	
	socket.handshake_headers = [PlayerAuth.get_auth_token()]
	socket.connect_to_url(JOIN_ROOM % room_id)
	set_process(true)

func _ready():
	set_process(false)
	on_connection.connect(func(con : WebSocketPeer):
		await get_tree().create_timer(1)
		con.send_text("hello"))
	
	change_received.connect(print)

func _process(_delta):
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
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		set_process(false)
