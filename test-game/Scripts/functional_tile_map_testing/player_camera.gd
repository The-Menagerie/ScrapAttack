extends Camera2D


func _on_freeroam_camera_camera_swap_to_player() -> void:
	if not self.is_current():
		self.make_current()
	pass # Replace with function body.
