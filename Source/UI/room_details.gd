extends Control

signal room_change_name(new_name : String)
signal change_permission(user : String, new_permission : bool)

@onready var user_example = $User
@onready var container = $ScrollContainer/Container

@onready var modify_edit = $ModifyEdit
@onready var modify_button = $ModifyRoomButton

@onready var toggle_name_change = $ToggleNameChange

var permission_change : bool = true

var active_room_name = ""

func find_node_of(username : String) -> Control:
	for clone in container.get_children():
		if not clone.has_meta("username"):
			continue
		
		var othername = clone.get_meta("username")
		if othername == username:
			return clone
	
	return null

func modify_layout(text : String):
	if toggle_name_change.button_pressed:
		modify_button.text = "RENAME ROOM"
		modify_edit.placeholder_text = "Deleting room..."
		modify_edit.tooltip_text = "Type a name for the room, or set to empty to delete"
		return
	
	var user = find_node_of(text)
	modify_edit.placeholder_text = "Username"
	modify_edit.tooltip_text = "Please type a username"
	if not user:
		modify_button.text = "ADD USER"
		permission_change = true
		return
	modify_button.text = "REMOVE USER"
	permission_change = false

func highlight_user(username : String):
	modify_edit.text = username
	modify_layout(username)

func add_user(display_name : String, username : String):
	var clone = user_example.duplicate()
	clone.set_meta("username", username)
	clone.get_node("Username").text = display_name
	clone.get_node("Button").pressed.connect(highlight_user.bind(username))
	
	clone.show()
	container.add_child(clone)

func clear_textbox():
	toggle_name_change.button_pressed = false
	modify_edit.text = ""
	modify_layout("")

func clear_details():
	for item in container.get_children():
		item.queue_free()
	
	clear_textbox()

func reflect_change(details : Dictionary):
	var changed = details.get("changed")
	var permission = details.get("new_permission")
	if not (changed is Array):
		return
	if not (permission is bool):
		return
	
	if not permission:
		for change in changed:
			if not (change is String):
				continue
			var clone = find_node_of(change)
			if clone:
				clone.queue_free()
		return
	
	for change in changed:
		add_user(change + "@" + change, change)

func populate_details(details : Dictionary):
	var characters = details.get("characters")
	if not (characters is Array):
		return
	
	clear_details()
	
	for character in characters:
		if not (character is Dictionary):
			continue
		var id = character.get("id")
		if not (id is float or id is int):
			continue
		id = int(id)
		var character_name = character.get("display")
		var username = character.get("username", "unnamed")
		var display_name = ("%s@%s" % [character_name, username]) if character_name else username
		add_user(display_name, username)

func request_permission(_a = null):
	var input = modify_edit.text
	
	if toggle_name_change.button_pressed:
		room_change_name.emit(input)
		return
	
	change_permission.emit(input, permission_change)

func _toggle_name_change(toggled_on: bool) -> void:
	modify_layout(modify_edit.text)
	
	if toggled_on:
		modify_edit.text = active_room_name
