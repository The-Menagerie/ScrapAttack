extends CharacterBody2D
class_name Enemy

enum EnemyState { IDLE, WALK }

@export var move_speed: float = 20.0
@export var idle_time: float = 5.0
@export var walk_time: float = 2.0
@export var detection_radius: float = 100.0
@export var agro_radius: float = 200.0
@export var knockback_duration: float = 0.15
@export var knockback_decay: float = 800.0
@export var attack_range: float = 50.0
@export var collides_with_other_enemies: bool = true

const ENEMY_BODY_LAYER: int = 6

@onready var animation_tree: AnimationTree = get_node_or_null("AnimationTree")
@onready var timer: Timer = get_node_or_null("Timer")
@onready var player: Node2D = get_tree().get_first_node_in_group("Player") as Node2D
@onready var weapon: WeaponEnemy = get_node_or_null("swordEnemy") as WeaponEnemy

var state_machine = null
var is_agro: bool = false
var move_direction: Vector2 = Vector2.ZERO
var current_state: EnemyState = EnemyState.IDLE
var stun_time_remaining: float = 0.0
var pending_stun_duration: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_time_remaining: float = 0.0
var movement_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	set_collision_mask_value(ENEMY_BODY_LAYER, collides_with_other_enemies)

	if animation_tree != null:
		state_machine = animation_tree.get("parameters/playback")

	pick_new_state()

func _physics_process(delta: float) -> void:
	movement_velocity = Vector2.ZERO

	if player == null:
		player = get_tree().get_first_node_in_group("Player") as Node2D

	if player != null:
		var distance_to_player := global_position.distance_to(
			player.global_position
		)
		var direction_to_player := global_position.direction_to(
			player.global_position
		)

		if not is_agro and distance_to_player <= detection_radius:
			is_agro = true

		if is_agro and distance_to_player > agro_radius:
			is_agro = false
			pick_new_state()

		if is_agro:
			move_direction = direction_to_player

			if distance_to_player <= attack_range:
				if weapon != null and weapon.can_attack:
					weapon.attack(player.global_position)
					movement_velocity = Vector2.ZERO
					current_state = EnemyState.IDLE
					_travel_state(&"Idle")
			else:
				movement_velocity = direction_to_player * move_speed
				current_state = EnemyState.WALK
				_travel_state(&"Walk")
				_set_blend_positions(direction_to_player)

		elif current_state == EnemyState.WALK:
			movement_velocity = move_direction * move_speed

	if knockback_time_remaining > 0.0:
		knockback_time_remaining = maxf(
			knockback_time_remaining - delta,
			0.0
		)
		movement_velocity = Vector2.ZERO
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(
			Vector2.ZERO,
			knockback_decay * delta
		)
		move_and_slide()

		if knockback_time_remaining <= 0.0:
			knockback_velocity = Vector2.ZERO
			stun_time_remaining = pending_stun_duration
			pending_stun_duration = 0.0

		return

	if stun_time_remaining > 0.0:
		stun_time_remaining = maxf(
			stun_time_remaining - delta,
			0.0
		)
		movement_velocity = Vector2.ZERO
		velocity = Vector2.ZERO
		_travel_state(&"Idle")
		move_and_slide()
		return

	velocity = movement_velocity + knockback_velocity
	move_and_slide()

	knockback_velocity = knockback_velocity.move_toward(
		Vector2.ZERO,
		knockback_decay * delta
	)

func select_new_direction() -> void:
	move_direction = Vector2(
		randi_range(-1, 1),
		randi_range(-1, 1)
	)

	if move_direction == Vector2.ZERO:
		move_direction = Vector2.RIGHT

	_set_blend_positions(move_direction)

func apply_knockback(direction: Vector2, force: float) -> void:
	knockback_velocity = direction * force
	knockback_time_remaining = knockback_duration

func pick_new_state() -> void:
	if is_agro:
		return

	if current_state == EnemyState.IDLE:
		_travel_state(&"Walk")
		current_state = EnemyState.WALK
		select_new_direction()

		if timer != null:
			timer.start(walk_time)
	elif current_state == EnemyState.WALK:
		velocity = Vector2.ZERO
		_travel_state(&"Idle")
		current_state = EnemyState.IDLE

		if timer != null:
			timer.start(idle_time)

func _on_timer_timeout() -> void:
	pick_new_state()

func apply_stun(duration: float) -> void:
	pending_stun_duration = maxf(pending_stun_duration, duration)

func _set_blend_positions(direction: Vector2) -> void:
	if animation_tree == null:
		return

	animation_tree.set("parameters/Walk/blend_position", direction)
	animation_tree.set("parameters/Idle/blend_position", direction)

func _travel_state(state_name: StringName) -> void:
	if state_machine == null:
		return

	state_machine.travel(state_name)
