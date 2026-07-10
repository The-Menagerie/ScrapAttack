extends CharacterBody2D

enum State { BUILD, ROAM }
@export var current_state: State = State.ROAM
@export var natural_speed = 20
var speed = 0

@onready var pointer_piv = $pointer_pivot
@onready var pointer = $pointer_pivot/Sprite2D/pointer_tip

func _ready() -> void:
	speed = natural_speed
	print(speed)

func _swap_state() -> void:
	match current_state:
		State.BUILD:
			current_state = State.ROAM
		State.ROAM:
			current_state = State.BUILD

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("camera_swap"):
		_swap_state()
	match current_state:
		State.BUILD:
			pointer_piv.show()
			pointer.active = true
		State.ROAM:
			pointer_piv.hide()
			pointer.active = false
	_process_free_movement(delta)
	
	
func _process_free_movement(delta: float) -> void:
	var player_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down", 0.25)
	velocity = speed*player_dir
	move_and_slide()
