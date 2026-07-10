extends Camera2D

signal camera_swap_to_player

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("camera_swap"):
		if self.is_current():
			camera_swap_to_player.emit()
		else:
			self.make_current()
	
	
