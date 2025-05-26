extends Control

func say(message : String):
	$Label.text = message

func _ready():
	get_tree().create_timer(3).timeout.connect(queue_free)
