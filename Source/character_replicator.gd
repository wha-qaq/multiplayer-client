extends Node2D

const base_message = preload("res://Scenes/Objects/message.tscn")

const INTERPOLATION_TIME = 0.15

func _ready():
	$BaseReplication.hide()

func spawn_character(uid : int, player_name : String, character_position : Vector2):
	var clone = $BaseReplication.duplicate()
	clone.set_meta("uid", uid)
	clone.set_meta("uname", player_name)
	
	add_child(clone)
	clone.global_position = character_position
	clone.show()

func find_character(uid : int) -> Node2D:
	for clone in get_children():
		if clone.has_meta("uid") and clone.get_meta("uid") == uid:
			return clone
	
	return null

func say_character(uid : int, str_message : String):
	var character = find_character(uid)
	if not character:
		return
	
	var message = base_message.instantiate()
	message.say(str_message)
	character.add_child(message)

func move_character(uid : int, character_position : Vector2):
	var character = find_character(uid)
	if not character:
		return
	
	var interpolation_time = 0
	if character.has_meta("tween"):
		character.get_meta("tween").kill()
		interpolation_time = INTERPOLATION_TIME
	
	var tween = character.create_tween()
	tween.tween_property(character, "global_position", character_position, interpolation_time)
	character.set_meta("tween", tween)

func del_character(uid):
	var character = find_character(uid)
	if not character:
		return
	
	character.queue_free()
