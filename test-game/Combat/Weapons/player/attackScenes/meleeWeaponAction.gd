extends Node2D
class_name MeleeWeaponAction

@export var cooldown: float = 0.35

var weapon: MeleeWeapon
var is_action_active: bool = false

func setup(owner_weapon: MeleeWeapon) -> void:
	weapon = owner_weapon

func can_execute() -> bool:
	return not is_action_active

func execute() -> bool:
	return false

func handle_incoming_attack(_attack: Attack) -> bool:
	return true

func prevents_movement() -> bool:
	return false
