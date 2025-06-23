extends Control

@onready var display_edit = $Panel/VSplit/Scroll/Vertical/DisplayName/HSplit/DisplayEdit

func apply_settings():
	RoomConnector.rename_self(display_edit.text)

func load_settings(username : String):
	display_edit.text = username
