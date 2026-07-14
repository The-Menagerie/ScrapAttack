extends CharacterBody2D

@export var move_speed : float = 100
@export var starting_direction : Vector2 = Vector2(0, 1)

@export var controller_aim_deadzone: float = 0.25
@export var weapon_rotation_offset: float = 0.0
@export var knockback_recovery: float = 700.0

@export var dash_multiplier = 2.0
@export var dash_duration = 0.15
@export var dash_smoke_scene: PackedScene
@export var dash_smoke_distance: float = 12.0

var movement_velocity := Vector2.ZERO
var knockback_velocity:= Vector2.ZERO

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var weapon: Weapon = $Sword
@onready var hitbox: HitboxComponent = $HitboxComponent

var is_dashing = false
var aim_direction: Vector2 = Vector2.RIGHT
var last_move_direction: Vector2 = Vector2.DOWN

func _ready():
	add_to_group("Player")
	last_move_direction = starting_direction.normalized()
	update_animation_parameters(starting_direction)

func _physics_process(_delta):
	update_weapon_aim()
	if Input.is_action_just_pressed("dash") and !is_dashing:
		dash()
	if Input.is_action_just_pressed("attack"):
		weapon.set_aim_direction(aim_direction, weapon_rotation_offset)
		weapon.attack()
	var input_direction = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down")-Input.get_action_strength("move_up")
	)
	if input_direction != Vector2.ZERO:
		last_move_direction = input_direction.normalized()
	
	knockback_velocity = knockback_velocity.move_toward(
		Vector2.ZERO,
		knockback_recovery * _delta
	)
	
	update_animation_parameters(input_direction)
	
	movement_velocity = input_direction * move_speed
	velocity = movement_velocity - knockback_velocity
	move_and_slide()
	pick_new_state()

func apply_knockback(direction: Vector2, force: float) -> void:
	knockback_velocity = direction.normalized() * force

func update_weapon_aim() -> void:
	var stick_direction := Input.get_vector(
		"aim_left",
		"aim_right",
		"aim_up",
		"aim_down"
	)
	
	if stick_direction.length() > controller_aim_deadzone:
		# Controller right stick
		aim_direction = stick_direction.normalized()
	else:
		# Mouse cursor
		var mouse_direction := get_global_mouse_position() - global_position
		if mouse_direction.length_squared() > 0.0:
			aim_direction = mouse_direction.normalized()

	if weapon.is_attacking:
		return

	weapon.set_aim_direction(aim_direction, weapon_rotation_offset)

func dash():
	is_dashing = true
	move_speed *= dash_multiplier
	hitbox.can_be_hit = false
	
	spawn_dash_smoke()

	await get_tree().create_timer(dash_duration).timeout

	move_speed /= dash_multiplier
	is_dashing = false
	hitbox.can_be_hit = true

func spawn_dash_smoke() -> void:
	if dash_smoke_scene == null:
		return

	var smoke := dash_smoke_scene.instantiate() as Node2D

	# Add it to the world rather than making it follow the player.
	get_parent().add_child(smoke)

	# Position it behind the direction the player is moving.
	smoke.global_position = global_position - (
		last_move_direction * dash_smoke_distance
	)

	smoke.rotation = last_move_direction.angle()

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
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
