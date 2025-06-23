extends CharacterBody2D

const SPEED = 400.0

var can_move : bool = true

func name_character(new_name : String):
	$Control/Label.text = new_name

func _physics_process(_delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * SPEED
	move_and_slide()
