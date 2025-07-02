extends ScrollContainer

func _on_resized() -> void:
	$Box.vertical = size.x <= 700
