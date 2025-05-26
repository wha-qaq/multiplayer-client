extends Node2D

const base_message = preload("res://Scenes/Objects/message.tscn")

func _ready():
	$BaseReplication.hide()

func spawn_character(uid : int):
	var clone = $BaseReplication.duplicate()
	clone.set_meta("uid", uid)
	
	add_child(clone)

func find_character(uid : int) -> Node2D:
	for clone in get_children():
		if clone.has_meta("uid") and clone.get_meta("uid") == uid:
			return clone
	
	return null

func say_character(uid : int, message : String):
	var char = find_character(uid)
	if not char:
		return

func move_character(uid : int, character_position : Vector2):
	var char = find_character(uid)
	if not char:
		return
	
	char.global_position = character_position

func del_character(uid):
	var char = find_character(uid)
	if not char:
		return
	
	char.queue_free()
