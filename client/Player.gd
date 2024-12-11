extends CharacterBody2D

signal me_movi()

@export var speed: int = 200
@export var id: int = 0

func get_input():
	var direction = Vector2()
	var posicionInicial = position
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed('ui_left'):
		direction.x -= 1
	if Input.is_action_pressed('ui_down'):
		direction.y += 1
	if Input.is_action_pressed('ui_up'):
		direction.y -= 1
	velocity = direction.normalized() * speed	

	

func _physics_process(_delta):
	var posicionInicial = position
	get_input()
	move_and_slide()
	
	if posicionInicial != position:
		me_movi.emit()
