extends Node2D

var ws = WebSocketPeer.new()
var URL = "wss://godot-with-sockets.onrender.com"
var enemy_scene = preload("res://Enemy.tscn")
var websocket_connected = false
var is_authenticated = false
		

var auth_data = {
	"type": "auth",
	"username": "",
	"password": ""
}

var game_data = {
	"username": ""
}

var enemies = []

func _ready():
	$Player.hide()	
	$LoginUI.show()
	$Player.on = false

func authenticate(username: String, password: String):
	auth_data["username"] = username
	auth_data["password"] = password
	ws.connect_to_url(URL)

func _closed():
	print("connection closed")
	$Player/Camera2D.enabled = false
	websocket_connected = false
	is_authenticated = false
	$Player.hide()
	$LoginUI.show()
	$Player.on = false
	
func _connected():
	print("connected to host")
	$Player.on = true
	$Player/Camera2D.enabled = true
	websocket_connected = true
	$Player.process_mode = Node.PROCESS_MODE_INHERIT
	# Send authentication data immediately after connection
	var json_string = JSON.stringify(auth_data)
	ws.send_text(json_string)

func _on_data(packet):
	var test_json_conv = JSON.new()
	var error = test_json_conv.parse(packet.get_string_from_utf8())
	if error == OK:
		var payload = test_json_conv.get_data()
		
		# Check for error messages from server
		if payload is Dictionary and payload.has("error"):
			print("Server error: ", payload["error"])
			ws.close()
			return
			
		# Handle the current server response format which is an array of players
		if payload is Array:
			# If not authenticated yet, we need to find ourselves in the game state
			if not is_authenticated:
				# Find the player that matches our auth username
				var my_player = null
				for player in payload:
					if player["username"] == auth_data["username"]:
						my_player = player
						break
				
				if my_player != null:
					is_authenticated = true
					$Player.show()
					$LoginUI.hide()
					# Store only the username
					game_data["username"] = my_player["username"]
					$Player.id = my_player["username"]
					print("Authentication successful, Player ID: ", game_data["username"])
			
			# Handle game state update
			if is_authenticated:
				for enemy in enemies:
					enemy.queue_free()
				enemies = []
				
				for player in payload:
					if player["username"] != game_data["username"]:
						var e = enemy_scene.instantiate()
						if player.has("position"):  # Check for position object
							e.position = Vector2(player["position"]["x"], player["position"]["y"])
						enemies.append(e)
						add_child(e)
		else:
			print("Unexpected payload format: ", payload)
	else:
		print("JSON Parse Error: ", error)

func _process(_delta):
	ws.poll()
	
	var state = ws.get_ready_state()
	match state:
		WebSocketPeer.STATE_OPEN:
			if not websocket_connected:
				_connected()
			# Handle incoming packets
			while ws.get_available_packet_count():
				_on_data(ws.get_packet())
			
			
			
		WebSocketPeer.STATE_CLOSED:
			if websocket_connected:
				_closed()

func _on_Button_pressed():
	if websocket_connected:
			ws.close(1000, str(game_data["username"]))
	get_tree().quit()

func _on_login_button_pressed():
	var username = $LoginUI/UsernameInput.text
	var password = $LoginUI/PasswordInput.text
	authenticate(username, password)


func _on_player_me_movi() -> void:
	if is_authenticated:
		var json_string = """{"msg_type":"player_pos","data":{"username":"%s","x":%d,"y":%d}}""" % [
						game_data["username"],
						$Player.position.x,
						$Player.position.y
					]
		ws.send_text(json_string)
		
