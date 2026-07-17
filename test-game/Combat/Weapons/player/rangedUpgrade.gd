extends Node2D
class_name RangedWeaponUpgrade

enum UpgradeSlot {
	ALT,
	SPECIAL
}

@export var upgrade_slot: UpgradeSlot = UpgradeSlot.ALT
@export var hud_icon: Texture2D

var weapon: LaserGunWeapon

func setup(owner_weapon: LaserGunWeapon) -> void:
	weapon = owner_weapon

func uses_hold_alt_attack() -> bool:
	return false

func alt_attack() -> void:
	return

func begin_alt_attack() -> void:
	return

func update_alt_attack(_delta: float) -> void:
	return

func release_alt_attack() -> void:
	return

func special_attack() -> void:
	return

func prevents_movement() -> bool:
	return false

func get_hud_icon() -> Texture2D:
	return hud_icon
