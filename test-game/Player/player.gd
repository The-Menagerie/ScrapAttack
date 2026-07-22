extends CharacterBody2D

@export var move_speed : float = 100
@export var starting_direction : Vector2 = Vector2(0, 1)

@export var controller_aim_deadzone: float = 0.25
@export var weapon_rotation_offset: float = 0.0
@export var knockback_recovery: float = 700.0

@export var dash_multiplier = 2.0
@export var dash_duration = 0.15
@export var dash_cooldown: float = 0.5
@export var dash_smoke_scene: PackedScene
@export var dash_smoke_distance: float = 12.0

var movement_velocity := Vector2.ZERO
var knockback_velocity:= Vector2.ZERO

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var dash_audio_player: AudioStreamPlayer = $DashAudioPlayer
@onready var weapon_icon_rect: TextureRect = $WeaponHud/WeaponIcon
@onready var upgrade_icon_rects: Array[TextureRect] = [
	$WeaponHud/UpgradeIconRow/UpgradeIcon1,
	$WeaponHud/UpgradeIconRow/UpgradeIcon2
]
@onready var weapon_cooldown_overlay: ColorRect = $WeaponHud/WeaponIcon/CooldownOverlay
@onready var upgrade_cooldown_overlays: Array[ColorRect] = [
	$WeaponHud/UpgradeIconRow/UpgradeIcon1/CooldownOverlay,
	$WeaponHud/UpgradeIconRow/UpgradeIcon2/CooldownOverlay
]


var is_dashing = false
var can_dash: bool = true
var aim_direction: Vector2 = Vector2.RIGHT
var last_move_direction: Vector2 = Vector2.DOWN
var dash_direction_override: Vector2 = Vector2.ZERO
var weapons: Array[Weapon] = []
var equipped_weapon_index: int = 0
var weapon: Weapon = null

var in_noclip = false

func _ready():
	add_to_group("Player")
	_refresh_weapons()
	last_move_direction = starting_direction.normalized()
	update_animation_parameters(starting_direction)
	_update_weapon_hud()

func _physics_process(_delta):
	update_weapon_aim()
	if Input.is_action_just_pressed("dash") and can_dash and !is_dashing and (weapon == null or not weapon.prevents_movement()):
		dash()
	if Input.is_action_just_pressed("swapWeapon"):
		swap_to_next_weapon()
	if weapon != null and weapon.uses_hold_alt_attack() and Input.is_action_just_pressed("altAttack"):
		weapon.set_aim_direction(aim_direction, weapon_rotation_offset)
		weapon.begin_alt_attack()
	if weapon != null and weapon.uses_hold_alt_attack() and Input.is_action_pressed("altAttack"):
		weapon.set_aim_direction(aim_direction, weapon_rotation_offset)
		weapon.update_alt_attack(_delta)
	if weapon != null and weapon.uses_hold_alt_attack() and Input.is_action_just_released("altAttack"):
		weapon.set_aim_direction(aim_direction, weapon_rotation_offset)
		weapon.release_alt_attack()
	if weapon != null and not weapon.uses_hold_alt_attack() and Input.is_action_just_pressed("altAttack"):
		weapon.set_aim_direction(aim_direction, weapon_rotation_offset)
		weapon.alt_attack()
	if weapon != null and Input.is_action_just_pressed("specialAttack"):
		weapon.set_aim_direction(aim_direction, weapon_rotation_offset)
		weapon.special_attack()
	if weapon != null and Input.is_action_just_pressed("attack"):
		weapon.set_aim_direction(aim_direction, weapon_rotation_offset)
		weapon.attack()
	var input_direction = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down")-Input.get_action_strength("move_up")
	)
	if weapon != null and weapon.prevents_movement():
		input_direction = Vector2.ZERO
	if is_dashing and dash_direction_override != Vector2.ZERO:
		input_direction = dash_direction_override

	if input_direction != Vector2.ZERO:
		last_move_direction = input_direction.normalized()
	
	knockback_velocity = knockback_velocity.move_toward(
		Vector2.ZERO,
		knockback_recovery * _delta
	)
	
	update_animation_parameters(input_direction)
	
	movement_velocity = input_direction * move_speed
	velocity = movement_velocity + knockback_velocity
	move_and_slide()
	pick_new_state()
	_update_weapon_cooldown_overlays()

func apply_knockback(direction: Vector2, force: float) -> void:
	knockback_velocity = direction.normalized() * force

func _refresh_weapons() -> void:
	weapons.clear()

	for child in get_children():
		if child is Weapon:
			weapons.append(child as Weapon)

	if weapons.is_empty():
		weapon = null
		equipped_weapon_index = 0
		_update_weapon_hud()
		return

	equipped_weapon_index = clampi(equipped_weapon_index, 0, weapons.size() - 1)
	_equip_weapon(equipped_weapon_index)

func _equip_weapon(index: int) -> void:
	if weapons.is_empty():
		weapon = null
		equipped_weapon_index = 0
		_update_weapon_hud()
		return

	equipped_weapon_index = posmod(index, weapons.size())
	weapon = weapons[equipped_weapon_index]

	for i in range(weapons.size()):
		var player_weapon := weapons[i]
		player_weapon.visible = i == equipped_weapon_index

	if weapon != null:
		weapon.set_aim_direction(aim_direction, weapon_rotation_offset)

	_update_weapon_hud()

func swap_to_next_weapon() -> void:
	if weapons.size() <= 1:
		return

	if weapon != null and weapon.is_attacking:
		return

	_equip_weapon(equipped_weapon_index + 1)

func _update_weapon_hud() -> void:
	if weapon_icon_rect == null:
		return

	if weapon == null:
		weapon_icon_rect.texture = null
		weapon_icon_rect.visible = false
		for icon_rect in upgrade_icon_rects:
			icon_rect.texture = null
			icon_rect.visible = false
		_set_overlay_progress(weapon_icon_rect, weapon_cooldown_overlay, 0.0)
		for overlay in upgrade_cooldown_overlays:
			_set_overlay_progress(null, overlay, 0.0)
		return

	weapon_icon_rect.texture = weapon.get_hud_icon()
	weapon_icon_rect.visible = weapon_icon_rect.texture != null

	var upgrade_icons := weapon.get_upgrade_hud_icons()
	for i in range(upgrade_icon_rects.size()):
		var icon_rect := upgrade_icon_rects[i]
		var icon := upgrade_icons[i] if i < upgrade_icons.size() else null
		icon_rect.texture = icon
		icon_rect.visible = icon != null

	_update_weapon_cooldown_overlays()

func _update_weapon_cooldown_overlays() -> void:
	if weapon == null:
		_set_overlay_progress(weapon_icon_rect, weapon_cooldown_overlay, 0.0)
		for overlay in upgrade_cooldown_overlays:
			_set_overlay_progress(null, overlay, 0.0)
		return

	_set_overlay_progress(
		weapon_icon_rect,
		weapon_cooldown_overlay,
		weapon.get_hud_cooldown_progress()
	)

	var upgrade_progresses := weapon.get_upgrade_hud_cooldown_progresses()
	for i in range(upgrade_icon_rects.size()):
		var progress := upgrade_progresses[i] if i < upgrade_progresses.size() else 0.0
		_set_overlay_progress(upgrade_icon_rects[i], upgrade_cooldown_overlays[i], progress)

func _set_overlay_progress(icon_rect: TextureRect, overlay: ColorRect, progress: float) -> void:
	if overlay == null:
		return

	var clamped_progress := clampf(progress, 0.0, 1.0)
	overlay.visible = clamped_progress > 0.0

	if not overlay.visible or icon_rect == null:
		return

	var inset_left := 1.0
	var inset_right := 1.0
	var inset_top := 1.0
	var inset_bottom := 1.0
	var usable_width := maxf(icon_rect.size.x - inset_left - inset_right, 0.0)
	var usable_height := maxf(icon_rect.size.y - inset_top - inset_bottom, 0.0)
	overlay.size = Vector2(usable_width, usable_height)
	overlay.position = Vector2(
		inset_left,
		inset_top + ((1.0 - clamped_progress) * usable_height)
	)

func handle_incoming_attack(attack: Attack) -> bool:
	if weapon == null:
		return true

	return weapon.handle_incoming_attack(attack)

func update_weapon_aim() -> void:
	if weapon == null:
		return

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

func dash(
	direction_override: Vector2 = Vector2.ZERO,
	multiplier_override: float = -1.0,
	duration_override: float = -1.0
) -> void:
	play_dash_audio()
	can_dash = false
	is_dashing = true
	dash_direction_override = (
		direction_override.normalized()
		if direction_override.length_squared() > 0.0
		else Vector2.ZERO
	)
	var resolved_multiplier: float = (
		dash_multiplier
		if multiplier_override <= 0.0
		else multiplier_override
	)
	var resolved_duration: float = (
		dash_duration
		if duration_override <= 0.0
		else duration_override
	)
	move_speed *= resolved_multiplier
	hitbox.can_be_hit = false

	var dash_visual_direction := dash_direction_override
	if dash_visual_direction == Vector2.ZERO:
		dash_visual_direction = last_move_direction
	else:
		last_move_direction = dash_visual_direction

	spawn_dash_smoke(dash_visual_direction)

	await get_tree().create_timer(resolved_duration, false).timeout

	move_speed /= resolved_multiplier
	is_dashing = false
	dash_direction_override = Vector2.ZERO
	hitbox.can_be_hit = true

	var resolved_cooldown := maxf(dash_cooldown, 0.0)
	if resolved_cooldown <= 0.0:
		can_dash = true
		return

	await get_tree().create_timer(resolved_cooldown, false).timeout

	if is_inside_tree():
		can_dash = true

func play_dash_audio() -> void:
	if dash_audio_player != null and dash_audio_player.stream != null:
		dash_audio_player.play()

func spawn_dash_smoke(smoke_direction: Vector2 = Vector2.ZERO) -> void:
	if dash_smoke_scene == null:
		return

	var smoke := dash_smoke_scene.instantiate() as Node2D
	var resolved_direction := smoke_direction

	if resolved_direction == Vector2.ZERO:
		resolved_direction = last_move_direction

	# Add it to the world rather than making it follow the player.
	smoke.process_mode = Node.PROCESS_MODE_PAUSABLE
	get_parent().add_child(smoke)

	# Position it behind the direction the player is moving.
	smoke.global_position = global_position - (
		resolved_direction * dash_smoke_distance
	)

	smoke.rotation = resolved_direction.angle()

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
	if Input.is_action_just_pressed("noclip"):
		if in_noclip == false:
			in_noclip = true
			for i in range(1,33):
				set_collision_mask_value(i, false)
		elif in_noclip == true:
			in_noclip = false
			set_collision_mask_value(1, true)
			set_collision_mask_value(2, true)
		
