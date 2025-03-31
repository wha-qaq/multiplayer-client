extends Control

func _ready() -> void:
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://Scenes/main_room.tscn")
