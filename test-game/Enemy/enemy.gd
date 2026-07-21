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
@export var ambient_sound_interval_min: float = 3.0
@export var ambient_sound_interval_max: float = 8.0
@export var ambient_sound_hearing_distance: float = 300.0
@export var ambient_sound_near_volume_db: float = 0.0
@export var ambient_sound_far_volume_db: float = -18.0

const ENEMY_BODY_LAYER: int = 6

@onready var animation_tree: AnimationTree = get_node_or_null("AnimationTree")
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var timer: Timer = get_node_or_null("Timer")
@onready var ambient_sound_timer: Timer = get_node_or_null("AmbientSoundTimer")
@onready var ambient_sound_player: AudioStreamPlayer2D = get_node_or_null("AmbientSoundPlayer")
@onready var player: Node2D = get_tree().get_first_node_in_group("Player") as Node2D
@onready var weapons: Array[WeaponEnemy] = _find_weapons()

var state_machine = null
var is_agro: bool = false
var move_direction: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.RIGHT
var facing_x_sign: float = 1.0
var current_state: EnemyState = EnemyState.IDLE
var stun_time_remaining: float = 0.0
var pending_stun_duration: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_time_remaining: float = 0.0
var movement_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	set_collision_mask_value(ENEMY_BODY_LAYER, collides_with_other_enemies)
	_ensure_unique_sprite_material()

	if weapons.is_empty():
		weapons = _find_weapons()

	if animation_tree != null:
		animation_tree.active = true
		state_machine = animation_tree.get("parameters/playback")

	if ambient_sound_timer != null and not ambient_sound_timer.timeout.is_connected(_on_ambient_sound_timer_timeout):
		ambient_sound_timer.one_shot = true
		ambient_sound_timer.timeout.connect(_on_ambient_sound_timer_timeout)
		_schedule_next_ambient_sound()

	_set_blend_positions(_get_animation_facing_direction())
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
			_update_facing_direction(direction_to_player)

			var ready_weapon := _select_weapon_for_distance(distance_to_player, true)
			var selected_weapon := ready_weapon
			if selected_weapon == null:
				selected_weapon = _select_weapon_for_distance(distance_to_player, false)

			if ready_weapon != null and ready_weapon.is_distance_in_attack_range(distance_to_player, attack_range):
				ready_weapon.attack(player.global_position)
				movement_velocity = Vector2.ZERO
				current_state = EnemyState.IDLE
				_set_blend_positions(_get_animation_facing_direction())
				_travel_state(&"Idle")
			elif selected_weapon != null and selected_weapon.is_distance_in_attack_range(distance_to_player, attack_range):
				movement_velocity = Vector2.ZERO
				current_state = EnemyState.IDLE
				_set_blend_positions(_get_animation_facing_direction())
				_travel_state(&"Idle")
			else:
				movement_velocity = direction_to_player * move_speed
				current_state = EnemyState.WALK
				_travel_state(&"Walk")
				_set_blend_positions(_get_animation_facing_direction())

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
		_set_blend_positions(_get_animation_facing_direction())
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

	_update_facing_direction(move_direction)
	_set_blend_positions(_get_animation_facing_direction())

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
		_set_blend_positions(_get_animation_facing_direction())
		_travel_state(&"Idle")
		current_state = EnemyState.IDLE

		if timer != null:
			timer.start(idle_time)

func _on_timer_timeout() -> void:
	pick_new_state()

func _on_ambient_sound_timer_timeout() -> void:
	_try_play_ambient_sound()
	_schedule_next_ambient_sound()

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

func _find_weapons() -> Array[WeaponEnemy]:
	var found_weapons: Array[WeaponEnemy] = []

	for child in get_children():
		if child is WeaponEnemy:
			found_weapons.append(child as WeaponEnemy)

	return found_weapons

func _select_weapon_for_distance(distance_to_player: float, require_ready: bool) -> WeaponEnemy:
	var best_weapon: WeaponEnemy = null
	var best_score := INF
	var best_max_distance := INF

	for candidate in weapons:
		if candidate == null or not is_instance_valid(candidate):
			continue

		if require_ready and not candidate.can_attack:
			continue

		var distance_score := candidate.get_attack_distance_score(distance_to_player, attack_range)
		var max_distance := candidate.get_attack_distance_max(attack_range)

		if distance_score < best_score:
			best_weapon = candidate
			best_score = distance_score
			best_max_distance = max_distance
			continue

		if is_equal_approx(distance_score, best_score) and max_distance < best_max_distance:
			best_weapon = candidate
			best_max_distance = max_distance

	return best_weapon

func _ensure_unique_sprite_material() -> void:
	if sprite == null or sprite.material == null:
		return

	sprite.material = sprite.material.duplicate()

func _update_facing_direction(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return

	facing_direction = direction.normalized()

	if absf(direction.x) > 0.01:
		facing_x_sign = signf(direction.x)

func _get_animation_facing_direction() -> Vector2:
	if facing_x_sign < 0.0:
		return Vector2.LEFT

	return Vector2.RIGHT

func _schedule_next_ambient_sound() -> void:
	if ambient_sound_timer == null:
		return

	var min_interval := maxf(ambient_sound_interval_min, 0.0)
	var max_interval := maxf(ambient_sound_interval_max, min_interval)
	ambient_sound_timer.start(randf_range(min_interval, max_interval))

func _try_play_ambient_sound() -> void:
	if ambient_sound_player == null or ambient_sound_player.stream == null:
		return

	if player == null:
		player = get_tree().get_first_node_in_group("Player") as Node2D

	if player == null:
		return

	var max_distance := maxf(ambient_sound_hearing_distance, 0.0)
	if max_distance <= 0.0:
		return

	var distance_to_player := global_position.distance_to(player.global_position)
	if distance_to_player > max_distance:
		return

	var distance_ratio := clampf(distance_to_player / max_distance, 0.0, 1.0)
	ambient_sound_player.volume_db = lerpf(
		ambient_sound_near_volume_db,
		ambient_sound_far_volume_db,
		distance_ratio
	)
	ambient_sound_player.play()
