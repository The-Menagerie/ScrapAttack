extends RangedWeapon
class_name LaserGunWeapon

@export var upgrade_scenes: Array[PackedScene] = []

var alt_upgrade: RangedWeaponUpgrade
var special_upgrade: RangedWeaponUpgrade

@onready var owner_visual: CanvasItem = get_parent().get_node_or_null("Sprite2D") as CanvasItem

func uses_hold_alt_attack() -> bool:
	return alt_upgrade != null and alt_upgrade.uses_hold_alt_attack()

func begin_alt_attack() -> void:
	if alt_upgrade != null:
		set_pending_hud_cooldown_slot(HudCooldownSlot.ALT)
		alt_upgrade.begin_alt_attack()

func update_alt_attack(delta: float) -> void:
	if alt_upgrade != null:
		alt_upgrade.update_alt_attack(delta)

func release_alt_attack() -> void:
	if alt_upgrade != null:
		alt_upgrade.release_alt_attack()

func alt_attack() -> void:
	if alt_upgrade != null and not alt_upgrade.uses_hold_alt_attack():
		set_pending_hud_cooldown_slot(HudCooldownSlot.ALT)
		alt_upgrade.alt_attack()

func prevents_movement() -> bool:
	if alt_upgrade != null and alt_upgrade.prevents_movement():
		return true

	if special_upgrade != null and special_upgrade.prevents_movement():
		return true

	return false

func special_attack() -> void:
	if special_upgrade != null:
		set_pending_hud_cooldown_slot(HudCooldownSlot.SPECIAL)
		special_upgrade.special_attack()

func _ready() -> void:
	super._ready()
	_apply_upgrades()

func flash_owner_white(duration: float) -> void:
	var shader_material := _get_owner_shader_material()

	if shader_material == null:
		return

	var original_flash_amount: float = float(
		shader_material.get_shader_parameter("flash_amount")
	)

	shader_material.set_shader_parameter("flash_amount", 1.0)
	await get_tree().create_timer(duration, false).timeout

	if not is_instance_valid(shader_material):
		return

	shader_material.set_shader_parameter("flash_amount", original_flash_amount)

func _get_owner_shader_material() -> ShaderMaterial:
	if not is_instance_valid(owner_visual):
		owner_visual = get_parent().get_node_or_null("Sprite2D") as CanvasItem

	if not is_instance_valid(owner_visual):
		return null

	var owner_node := owner_visual

	while owner_node != null:
		var shader_material := owner_node.material as ShaderMaterial

		if shader_material != null:
			return shader_material

		owner_node = owner_node.get_parent() as CanvasItem

	return null

func _apply_upgrades() -> void:
	for upgrade_scene in upgrade_scenes:
		var upgrade := _instantiate_upgrade_scene(upgrade_scene)

		if upgrade == null:
			continue

		add_child(upgrade)
		upgrade.setup(self)

		match upgrade.upgrade_slot:
			RangedWeaponUpgrade.UpgradeSlot.SPECIAL:
				if special_upgrade != null:
					special_upgrade.queue_free()
				special_upgrade = upgrade
			_:
				if alt_upgrade != null:
					alt_upgrade.queue_free()
				alt_upgrade = upgrade

func _instantiate_upgrade_scene(scene: PackedScene) -> RangedWeaponUpgrade:
	if scene == null:
		return null

	var upgrade_instance := scene.instantiate()

	if not (upgrade_instance is RangedWeaponUpgrade):
		push_warning("Upgrade scene must inherit RangedWeaponUpgrade.")
		return null

	return upgrade_instance as RangedWeaponUpgrade

func get_upgrade_hud_icons() -> Array[Texture2D]:
	var icons: Array[Texture2D] = []

	if alt_upgrade != null:
		var alt_icon := alt_upgrade.get_hud_icon()
		if alt_icon != null:
			icons.append(alt_icon)

	if special_upgrade != null:
		var special_icon := special_upgrade.get_hud_icon()
		if special_icon != null:
			icons.append(special_icon)

	return icons

func get_upgrade_hud_cooldown_progresses() -> Array[float]:
	var progresses: Array[float] = []

	if alt_upgrade != null:
		progresses.append(get_slot_hud_cooldown_progress(HudCooldownSlot.ALT))

	if special_upgrade != null:
		progresses.append(get_slot_hud_cooldown_progress(HudCooldownSlot.SPECIAL))

	return progresses
