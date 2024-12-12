extends RigidBody2D
@export var id: int = 0



@export var  on = false
		
signal me_movi()

func _physics_process(delta: float) -> void:
	var posicionInicial = position
	
	
	if on:
		if Input.is_action_just_pressed("ui_reset"):
			position = Vector2(550,-550)
		if Input.is_action_just_pressed("salto"):
			print("si")
			#aplicar impulso
			apply_central_impulse(Vector2(0,-500) + constant_force)
		if Input.is_action_pressed("girar_horario"):
			apply_torque(10000)
		if Input.is_action_pressed("girar_antiHorario"):
			apply_torque(-10000)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
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
