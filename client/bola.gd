extends CharacterBody2D
@export var id: int = 0

@export var speed = 300.0
@export var JUMP_VELOCITY = -400.0
@export var bounce_strength: float = 0.5  
@export var rotation_speed: float = 5.0


		
signal me_movi()

func _physics_process(delta: float) -> void:
	var posicionInicial = position
	
	if Input.is_action_just_pressed("ui_reset"):
		position = Vector2(550,-550)
		print("hola")
	
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	move_and_slide()
	
	if posicionInicial != position:
		me_movi.emit()
	
	
	



#
#func get_input():
	#var direction = Vector2()
	#var posicionInicial = position
	#if Input.is_action_pressed("ui_right"):
		#direction.x += 1
	#if Input.is_action_pressed('ui_left'):
		#direction.x -= 1
	#if Input.is_action_pressed('ui_down'):
		#direction.y += 1
	#if Input.is_action_pressed('ui_up'):
		#direction.y -= 1
	#velocity = direction.normalized() * speed	
#
	#
