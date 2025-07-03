extends Label

func _resized():
	var scaling = minf(get_viewport_rect().size.x / 1200.0, 1.0)
	add_theme_font_size_override("font_size", int(96.0 * scaling))

func _ready() -> void:
	get_viewport().size_changed.connect(_resized)
	_resized()
