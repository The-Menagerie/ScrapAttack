extends Weapon
class_name MeleeWeapon

@export var attack_damage := 10.0
@export var knockback_force := 100.0
@export var attack_duration: float = 0.15
@export var stun_duration: float = 0.0

@onready var weapon_sprite: Sprite2D = $Sprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var attack_timer: Timer = $AttackTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	super._ready()
	attack_shape.disabled = true
	weapon_sprite.visible = false
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_area.area_entered.connect(_on_hitbox_area_entered)

func _begin_attack() -> void:
	attack_shape.set_deferred("disabled", false)
	attack_timer.start(attack_duration)
	play_attack_animation()

func play_attack_animation() -> void:
	weapon_sprite.visible = true
	animation_player.play("Attack")

func _on_attack_timer_timeout() -> void:
	attack_shape.set_deferred("disabled", true)
	weapon_sprite.visible = false
	animation_player.stop()
	finish_attack()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area is HitboxComponent:
		var hitbox := area as HitboxComponent
		var attack := Attack.new()
		attack.attack_damage = attack_damage
		attack.knockback_force = knockback_force
		attack.attack_position = global_position
		attack.stun_duration = stun_duration
		hitbox.damage(attack)
