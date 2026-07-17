extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.animation_finished.connect(_on_animation_finished)
	animation_player.play(&"smoke")

func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == &"smoke":
		queue_free()
