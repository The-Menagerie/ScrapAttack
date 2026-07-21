extends MeleeWeaponAction
class_name ScrapUpgrade

enum UpgradeSlot {
	ALT,
	SPECIAL
}

@export var upgrade_slot: UpgradeSlot = UpgradeSlot.ALT
@export var hud_icon: Texture2D

@onready var audio_player: AudioStreamPlayer = get_node_or_null("AudioStreamPlayer")

func get_hud_icon() -> Texture2D:
	return hud_icon

func play_upgrade_audio() -> void:
	if audio_player != null and audio_player.stream != null:
		audio_player.play()
