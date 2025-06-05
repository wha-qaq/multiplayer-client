extends Control

@onready var AuthPanel = $AuthPanel
@onready var SignInPanel = $AuthPanel/SignIn
@onready var SignUpPanel = $AuthPanel/SignUp
@onready var SignInUsername = $AuthPanel/SignIn/Username
@onready var SignInPassword = $AuthPanel/SignIn/Password
@onready var SignUpUsername = $AuthPanel/SignUp/Username
@onready var SignUpPassword = $AuthPanel/SignUp/Password
@onready var SignUpConfirmP = $AuthPanel/SignUp/PasswordConfirm

@onready var notifications = $Notifications/Container
@onready var notif = $Notifications/Label

func continue_room_select():
	get_tree().change_scene_to_file("res://Scenes/room_select.tscn")

func start_playing():
	if !PlayerAuth.can_login():
		$AuthPanel.show()
		PlayerAuth.on_authenticated.connect(continue_room_select)
		return
	
	continue_room_select()

func start_sign_in(_a = null) -> void:
	PlayerAuth.request_login(SignInUsername.text, SignInPassword.text)

func start_sign_up(_a = null) -> void:
	if SignUpConfirmP.text != SignUpPassword.text:
		MessagingSystem.add_message("Passwords do not match")
		return
	
	PlayerAuth.request_creation(SignUpUsername.text, SignUpPassword.text)

func _show_sign_up() -> void:
	SignInPanel.hide()
	SignUpPanel.show()

func _show_sign_in() -> void:
	SignInPanel.show()
	SignUpPanel.hide()

func show_message(text : String):
	var clone = notif.duplicate()
	clone.text = text
	notifications.add_child(clone)
	notifications.move_child(clone, 0)
	
	var tween = clone.create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUINT)
	clone.modulate.a = 0
	clone.show()
	
	tween.tween_property(clone, "modulate:a", 1, 0.8).from(0).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1 + minf(len(text) * 0.025, 3.5))
	tween.tween_property(clone, "modulate:a", 0, 0.8).from(1)
	tween.tween_callback(clone.queue_free)

func _ready() -> void:
	var found = MessagingSystem.flush_messages()
	for message in found:
		show_message(found)
	MessagingSystem.on_message.connect(show_message)
