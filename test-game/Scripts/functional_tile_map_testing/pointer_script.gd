extends Node2D

@export var rotation_speed = 2

func _physics_process(delta: float) -> void:
	_schmove_pointer(delta)
	
	
func _schmove_pointer(delta:float) -> void:
	var player_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down", 0.25)
	if player_dir.length() > 0:
		var player_ang = round(player_dir.angle()*180/PI + 90)
		if player_ang < 0:
			player_ang = 360+player_ang
		
		if self.rotation_degrees == player_ang:
			print("We all good")
		else:
			var deg_dif_cl = player_ang - self.rotation_degrees
			if deg_dif_cl < 0:
				deg_dif_cl = deg_dif_cl+360
			var deg_dif_ccl = 360 - deg_dif_cl
			
			print("Clockwise = "+str(deg_dif_cl))
			print("Counterclockwise = "+str(deg_dif_ccl))
			if deg_dif_cl <= deg_dif_ccl:
				print("attempting to rotate clockwise")
				#if deg_dif_ccl < 10:
				self.rotation_degrees = self.rotation_degrees + rotation_speed
			else:
				print("attempting to rotate counter clockwise")
				self.rotation_degrees = self.rotation_degrees - rotation_speed
			
			if self.rotation_degrees > 360:
				self.rotation_degrees = int(round(self.rotation_degrees))%360
			if self.rotation_degrees < 0:
				self.rotation_degrees = int(round(self.rotation_degrees))%360 + 360
				print(self.rotation_degrees)
				
			
			
		

	
