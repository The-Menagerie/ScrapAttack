extends MeleeWeapon
class_name SwordWeapon

@export_range(0.0, 1.0, 0.05) var passive_damage_reduction: float = 0.1

func handle_incoming_attack(attack: Attack) -> bool:
	attack.attack_damage *= maxf(0.0, 1.0 - passive_damage_reduction)
	return super.handle_incoming_attack(attack)
