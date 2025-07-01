extends Control

@onready var stick = $Stick

var active : bool = false

func get_value():
	return Vector2(stick.anchor_left, stick.anchor_top) * 2 - Vector2.ONE

func set_value(vector : Vector2):
	stick.anchor_left = vector.x
	stick.anchor_right = vector.x
	stick.anchor_top = vector.y
	stick.anchor_bottom = vector.y

func set_by_position(event_position : Vector2):
	var rel_position = event_position - global_position
	var scaled_position : Vector2 = rel_position / custom_minimum_size
	var real_value = scaled_position - Vector2.ONE / 2
	set_value(real_value.normalized() * clampf(real_value.length(), 0, 0.5) + Vector2.ONE / 2)

func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		return
	
	if event is InputEventScreenTouch and event.is_pressed():
		var touch_offset = event.position - global_position
		if touch_offset.x < 0.0 or touch_offset.x > custom_minimum_size.x:
			return
		if touch_offset.y < 0.0 or touch_offset.y > custom_minimum_size.y:
			return
		
		active = true
		set_by_position(event.position)
		return
	
	if event is InputEventScreenDrag and active:
		set_by_position(event.position)
		return
	
	if event is InputEventScreenTouch and not event.is_pressed():
		active = false
		set_value(Vector2.ONE / 2)
		return
