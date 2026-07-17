extends MeleeWeaponAction
class_name ScrapUpgrade

enum UpgradeSlot {
	ALT,
	SPECIAL
}

@export var upgrade_slot: UpgradeSlot = UpgradeSlot.ALT
@export var hud_icon: Texture2D

func get_hud_icon() -> Texture2D:
	return hud_icon
