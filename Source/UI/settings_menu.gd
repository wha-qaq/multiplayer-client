extends Control

const MINIMUM_SIZE = 800

@onready var display_edit = $Panel/Scroll/Vertical/DisplayName/HSplit/DisplayEdit
@onready var panel = $Panel

func apply_settings():
	RoomConnector.rename_self(display_edit.text)

func load_settings(username : String):
	display_edit.text = username

func _ready():
	get_viewport().size_changed.connect(_resize_panel)

func _resize_panel() -> void:
	if get_viewport_rect().size.x <= MINIMUM_SIZE:
		panel.anchor_left = 0
		panel.offset_left = 16
		panel.anchor_right = 0
		panel.grow_horizontal = GrowDirection.GROW_DIRECTION_END
		return
	
	panel.anchor_left = 0.2
	panel.offset_left = 0
	panel.anchor_right = 0.8
	panel.grow_horizontal = GrowDirection.GROW_DIRECTION_BOTH
