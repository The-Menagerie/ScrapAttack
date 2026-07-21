extends Weapon
class_name MeleeWeapon

@export_group("Main Attack")
@export var attack_damage := 10.0
@export var knockback_force := 100.0
@export var attack_duration: float = 0.15
@export var stun_duration: float = 0.0

@export_group("Weapon Abilities")
@export var special_attack_scene: PackedScene
@export var upgrade_scenes: Array[PackedScene] = []

@onready var weapon_sprite: Sprite2D = $Sprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var attack_timer: Timer = $AttackTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

var alt_attack_action: MeleeWeaponAction
var special_attack_action: MeleeWeaponAction
var active_attack_damage: float = 0.0
var active_knockback_force: float = 0.0
var active_stun_duration: float = 0.0
var default_sprite_scale: Vector2 = Vector2.ONE
var default_hitbox_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	super._ready()
	special_attack_action = _instantiate_action_scene(special_attack_scene)
	_apply_upgrades()
	attack_shape.disabled = true
	weapon_sprite.visible = false
	default_sprite_scale = weapon_sprite.scale
	default_hitbox_scale = attack_shape.scale
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_area.area_entered.connect(_on_hitbox_area_entered)

func attack() -> void:
	if not can_attack:
		return

	set_pending_hud_cooldown_slot(HudCooldownSlot.PRIMARY)
	can_attack = false
	is_attacking = true
	set_cooldown_override(attack_cooldown)
	_begin_attack()

func alt_attack() -> void:
	_try_execute_action(alt_attack_action, HudCooldownSlot.ALT)

func special_attack() -> void:
	_try_execute_action(special_attack_action, HudCooldownSlot.SPECIAL)

func _begin_attack() -> void:
	active_attack_damage = attack_damage
	active_knockback_force = knockback_force
	active_stun_duration = stun_duration
	weapon_sprite.scale = default_sprite_scale
	attack_shape.scale = default_hitbox_scale
	animation_player.speed_scale = 1.0
	attack_timer.start(attack_duration)
	attack_shape.set_deferred("disabled", false)
	play_attack_animation()

func play_attack_animation() -> void:
	weapon_sprite.visible = true
	if audio_player != null and audio_player.stream != null:
		audio_player.play()
	animation_player.play("Attack")

func _on_attack_timer_timeout() -> void:
	attack_shape.set_deferred("disabled", true)
	weapon_sprite.visible = false
	weapon_sprite.scale = default_sprite_scale
	attack_shape.scale = default_hitbox_scale
	animation_player.stop()
	animation_player.speed_scale = 1.0
	finish_attack()

func _on_hitbox_area_entered(area: Area2D) -> void:
	apply_attack_to_hitbox(
		area,
		active_attack_damage,
		active_knockback_force,
		active_stun_duration,
		global_position
	)

func apply_attack_to_hitbox(
	area: Area2D,
	damage_amount: float,
	knockback_amount: float,
	stun_amount: float,
	attack_position: Vector2
) -> void:
	if area is HitboxComponent:
		var hitbox := area as HitboxComponent
		var attack := Attack.new()
		attack.attack_damage = damage_amount
		attack.knockback_force = knockback_amount
		attack.attack_position = attack_position
		attack.stun_duration = stun_amount
		var source_node := get_parent() as Node2D
		if is_instance_valid(source_node):
			attack.source_node = source_node
		hitbox.damage(attack)

func handle_incoming_attack(attack: Attack) -> bool:
	if special_attack_action != null:
		return special_attack_action.handle_incoming_attack(attack)

	return true

func prevents_movement() -> bool:
	if special_attack_action != null and special_attack_action.prevents_movement():
		return true

	return false

func _instantiate_action_scene(scene: PackedScene) -> MeleeWeaponAction:
	if scene == null:
		return null

	var action_instance := scene.instantiate()

	if not (action_instance is MeleeWeaponAction):
		push_warning("Weapon action scene must inherit MeleeWeaponAction.")
		return null

	add_child(action_instance)
	var action := action_instance as MeleeWeaponAction
	action.setup(self)
	return action

func _try_execute_action(action: MeleeWeaponAction, slot: HudCooldownSlot) -> bool:
	if action == null or not can_attack:
		return false

	set_pending_hud_cooldown_slot(slot)
	can_attack = false
	is_attacking = true

	if not action.execute():
		can_attack = true
		is_attacking = false
		return false

	return true

func _apply_upgrades() -> void:
	for upgrade_scene in upgrade_scenes:
		var upgrade := _instantiate_upgrade_scene(upgrade_scene)

		if upgrade == null:
			continue

		add_child(upgrade)
		upgrade.setup(self)

		match upgrade.upgrade_slot:
			ScrapUpgrade.UpgradeSlot.SPECIAL:
				if special_attack_action != null:
					special_attack_action.queue_free()
				special_attack_action = upgrade
			_:
				if alt_attack_action != null:
					alt_attack_action.queue_free()
				alt_attack_action = upgrade

func _instantiate_upgrade_scene(scene: PackedScene) -> ScrapUpgrade:
	if scene == null:
		return null

	var upgrade_instance := scene.instantiate()

	if not (upgrade_instance is ScrapUpgrade):
		push_warning("Upgrade scene must inherit ScrapUpgrade.")
		return null

	return upgrade_instance as ScrapUpgrade

func get_upgrade_hud_icons() -> Array[Texture2D]:
	var icons: Array[Texture2D] = []

	if alt_attack_action is ScrapUpgrade:
		var alt_icon := (alt_attack_action as ScrapUpgrade).get_hud_icon()
		if alt_icon != null:
			icons.append(alt_icon)

	if special_attack_action is ScrapUpgrade:
		var special_icon := (special_attack_action as ScrapUpgrade).get_hud_icon()
		if special_icon != null:
			icons.append(special_icon)

	return icons

func get_upgrade_hud_cooldown_progresses() -> Array[float]:
	var progresses: Array[float] = []

	if alt_attack_action is ScrapUpgrade:
		progresses.append(get_slot_hud_cooldown_progress(HudCooldownSlot.ALT))

	if special_attack_action is ScrapUpgrade:
		progresses.append(get_slot_hud_cooldown_progress(HudCooldownSlot.SPECIAL))

	return progresses
