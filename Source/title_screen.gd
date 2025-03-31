extends Control

func start_playing():
	if !PlayerAuth.can_login():
		$AuthPanel.show()
		return
	
	get_tree().change_scene_to_file("res://Scenes/room_select.tscn")

func _ready():
	pass
