extends Control

@onready var AuthPanel = $AuthPanel
@onready var SignInPanel = $AuthPanel/SignIn
@onready var SignUpPanel = $AuthPanel/SignUp
@onready var SignInUsername = $AuthPanel/SignIn/Username
@onready var SignInPassword = $AuthPanel/SignIn/Password
@onready var SignUpUsername = $AuthPanel/SignUp/Username
@onready var SignUpPassword = $AuthPanel/SignUp/Password

func continue_room_select():
	get_tree().change_scene_to_file("res://Scenes/room_select.tscn")

func start_playing():
	if !PlayerAuth.can_login():
		$AuthPanel.show()
		PlayerAuth.on_authenticated.connect(continue_room_select)
		return
	
	continue_room_select()

func _on_sign_in_pressed() -> void:
	PlayerAuth.request_login(SignInUsername.text, SignInPassword.text)

func _on_sign_up_pressed() -> void:
	PlayerAuth.request_creation(SignUpUsername.text, SignUpPassword.text)

func _show_sign_up() -> void:
	SignInPanel.hide()
	SignUpPanel.show()

func _show_sign_in() -> void:
	SignInPanel.show()
	SignUpPanel.hide()
