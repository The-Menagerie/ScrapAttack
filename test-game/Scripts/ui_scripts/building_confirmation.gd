extends Control

@export var animation_player: Node

var on_confirm = false
var on_deny = false

func _ready() -> void:
	BuildEnv.start_buildin.connect(appear)
	BuildEnv.stop_buildin.connect(disappear)
	BuildEnv.valid_blueprint.connect(confirm_on)
	BuildEnv.remove_blueprint.connect(confirm_off)
	
func appear(_building:Dictionary) -> void:
	animation_player.play_section("Fade In")

func disappear() -> void:
	animation_player.play_section("Fade Out")

func confirm_on() -> void:
	$Confirm.disabled = false

func confirm_off() -> void:
	$Confirm.disabled = true

func _on_confirm_mouse_entered() -> void:
	on_confirm = true
	pass # Replace with function body.

func _on_confirm_mouse_exited() -> void:
	on_confirm = false
	pass # Replace with function body.

func _on_confirm_button_up() -> void:
	if on_confirm:
		BuildEnv.build_done.emit()
		pass
	pass # Replace with function body.


func _on_deny_mouse_entered() -> void:
	on_deny = true
	pass # Replace with function body.

func _on_deny_mouse_exited() -> void:
	on_deny = false
	pass # Replace with function body.

func _on_deny_button_up() -> void:
	if on_deny == true:
		BuildEnv.stop_buildin.emit()
	pass # Replace with function body.
	
