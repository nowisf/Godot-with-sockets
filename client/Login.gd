extends Control

@onready var username_input: LineEdit = $Container/UsernameInput
@onready var password_input: LineEdit = $Container/PasswordInput
@onready var start_button: Button = $Container/StartButton
@onready var error_label: Label = $Container/ErrorLabel

func _ready() -> void:
	start_button.disabled = true
	username_input.text_changed.connect(_on_input_changed)
	password_input.text_changed.connect(_on_input_changed)
	start_button.pressed.connect(_on_start_pressed)
	
	# Set password input to secret mode
	password_input.secret = true

func _on_input_changed(_new_text: String) -> void:
	var username = username_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	start_button.disabled = username.is_empty() or password.is_empty()
	error_label.text = ""

func _on_start_pressed() -> void:
	var username = username_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	if username.length < 3:
		error_label.text = "Username must be at least 3 characters"
		return
		
	if password.length < 6:
		error_label.text = "Password must be at least 6 characters"
		return
	
	# Pass credentials to Game scene
	get_tree().change_scene_to_file("res://Game.tscn")
	await get_tree().process_frame
	get_node("/root/Game").set_credentials(username, password) 
