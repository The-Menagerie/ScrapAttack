extends CharacterBody2D

@export var move_speed : float = 100
@export var starting_direction : Vector2 = Vector2(0, 1)
@export var dash_multiplier = 2.0
@export var dash_duration = 0.15

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")

var is_dashing = false
var in_noclip = false

func _ready():
	add_to_group("Player")
	update_animation_parameters(starting_direction)

func _physics_process(_delta):
	if Input.is_action_just_pressed("dash") and !is_dashing:
		dash()
	var input_direction = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down")-Input.get_action_strength("move_up")
	)
	
	update_animation_parameters(input_direction)
	
	velocity = input_direction * move_speed
	
	move_and_slide()
	pick_new_state()

func dash():
	is_dashing = true
	move_speed *= dash_multiplier

	await get_tree().create_timer(dash_duration).timeout

	move_speed /= dash_multiplier
	is_dashing = false

func update_animation_parameters(move_input : Vector2):
	if(move_input != Vector2.ZERO):
		animation_tree.set("parameters/Walk/blend_position", move_input)
		animation_tree.set("parameters/Idle/blend_position", move_input)
	

func pick_new_state():
		if(velocity != Vector2.ZERO):
			state_machine.travel("Walk")
		else:
			state_machine.travel("Idle")

# DELETE ME LATER
func _input(event):
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		get_tree().quit()
	elif Input.is_action_just_pressed("noclip"):
		if in_noclip == false:
			in_noclip = true
			for i in range(1,33):
				set_collision_mask_value(i, false)
		elif in_noclip == true:
			in_noclip = false
			set_collision_mask_value(1, true)
			set_collision_mask_value(2, true)
		
