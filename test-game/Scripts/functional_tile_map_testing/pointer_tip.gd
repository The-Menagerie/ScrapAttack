extends Node2D

@export var hover_tilemap: Node
@export var main_tilemap: Node
@export var chasm_tilemap: Node

var active = true

func _physics_process(delta: float) -> void:
	var old_hovered = hover_tilemap.get_used_cells_by_id(1, Vector2i(0,0))
	for i in old_hovered:
		hover_tilemap.set_cell(i,-1)
	if active == true:
		var coords = self.global_position
		var map_coords = hover_tilemap.local_to_map(coords)
		hover_tilemap.set_cell(map_coords, 1, Vector2i(0,0))
		
		if Input.is_action_pressed("interact_1"):
			var chasm_exist = chasm_tilemap.get_cell_source_id(map_coords)
			if chasm_exist != -1:
				var chasm_data = chasm_tilemap.get_cell_tile_data(map_coords).get_custom_data("Chasm")
				if chasm_data == true:
					get_tree().quit()
			main_tilemap.set_cell(map_coords,-1)
