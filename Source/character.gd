extends CharacterBody2D

const SPEED = 400.0

func say(text: String):
	print(text)

func _physics_process(_delta: float) -> void:
	velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * SPEED
	move_and_slide()
