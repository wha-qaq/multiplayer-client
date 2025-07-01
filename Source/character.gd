extends CharacterBody2D

const SPEED = 400.0

var can_move : bool = true
var last_dir = Vector2.DOWN

@onready var joystick = $"../GUI/Main/Joystick"

func name_character(new_name : String):
	$Control/Label.text = new_name

func get_dir_from(vector : Vector2):
	if abs(vector.y) >= abs(vector.x):
		return "up" if vector.y < 0 else "down"
	return "left" if vector.x < 0 else "right"

func _physics_process(_delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * SPEED
	if joystick.visible:
		velocity = joystick.get_value() * SPEED
	
	if velocity.length_squared() != 0:
		last_dir = velocity
		$AnimatedSprite2D.play("walk_" + get_dir_from(last_dir))
	else:
		$AnimatedSprite2D.play("idle_" + get_dir_from(last_dir))
	
	move_and_slide()

func _ready() -> void:
	if OS.has_feature("android"):
		joystick.show()

func _try_bridge_trigger(body: Node2D) -> void:
	if body != self:
		return
	
	collision_mask = 2

func _try_del_trigger(body : Node2D) -> void:
	if body != self:
		return
	
	collision_mask = 1
