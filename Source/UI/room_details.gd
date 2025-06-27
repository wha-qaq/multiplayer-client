extends Control

signal change_permission(user : String, new_permission : bool)

@onready var user_example = $User
@onready var container = $ScrollContainer/Container

@onready var username_input = $LineEdit
@onready var change_perms = $change_permission

var permission_change : bool = true

func find_node_of(username : String) -> Control:
	for clone in container.get_children():
		if not clone.has_meta("username"):
			continue
		
		var othername = clone.get_meta("username")
		if othername == username:
			return clone
	
	return null

func modify_layout(text : String):
	var user = find_node_of(text)
	if not user:
		change_perms.text = "ADD USER"
		permission_change = true
		return
	change_perms.text = "REMOVE USER"
	permission_change = false

func highlight_user(username : String):
	username_input.text = username
	modify_layout(username)

func add_user(display_name : String, username : String):
	var clone = user_example.duplicate()
	clone.set_meta("username", username)
	clone.get_node("Username").text = display_name
	clone.get_node("Button").pressed.connect(highlight_user.bind(username))
	
	clone.show()
	container.add_child(clone)

func clear_details():
	for item in container.get_children():
		item.queue_free()
	
	username_input.text = ""
	modify_layout("")

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
	
	var messages = details.get("messages")
	if not (characters is Array):
		return

func request_permission():
	var username = username_input.text
	change_permission.emit(username, permission_change)
	
	username_input.text = ""
	modify_layout("")
