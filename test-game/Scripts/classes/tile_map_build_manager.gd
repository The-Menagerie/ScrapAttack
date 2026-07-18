##A class for managing tilemaps underneath for build mode. Enables hovered tiles and editing of tiles.
class_name build_manager extends Node2D

@export var tilemaps: Array[Node] ##Array of tilemaps to be affected. Should be ordered in a stack, 0 is the highest.
@export var hovermap: Node ##The tilemap setup for hover selected tiles. Make sure that the icon you use for hovering is on source ID 0 and atlas coordinates (0,0) in the tile set for this map
@export var buildmap: Node ##The building tilemap

var current_building: Dictionary
var active_hovered = []
var build_mode = false
var placed = false
var valid_placement = false
			

func _ready() -> void:
	BuildEnv.start_buildin.connect(building_start)
	BuildEnv.stop_buildin.connect(building_stop)
	BuildEnv.build_done.connect(complete_building)
	pass

func _input(event):
	# Mouse in viewport coordinates.
	if build_mode:
		if event is InputEventMouse && placed != true: # 
			active_hovered = hover_mark(get_global_mouse_position())
		if event is InputEventMouseButton && event.is_pressed() == true && event.get_button_index() == 1 && valid_placement:
			placed = true
			if valid_placement:
				BuildEnv.valid_blueprint.emit()
			
		if event is InputEventMouseButton && event.is_pressed() == true && event.get_button_index() == 2 && placed == true:
			placed = false
			if valid_placement:
				BuildEnv.remove_blueprint.emit()

func hover_mark(coordinates: Vector2) -> Array[Vector2]:
	var hovered_cells: Array[Vector2] = []
	var map_coordinates = []
	var cur_coords = hovermap.local_to_map(coordinates)
	var validity_count = 0
	var gridspace = current_building["gridspace"]
	valid_placement = false
	gridspace.reverse()
	for i in gridspace:
		i.reverse()
		for k in i:
			if k:
				map_coordinates.append(cur_coords)
			cur_coords.x = cur_coords.x - 1
		cur_coords.x = cur_coords.x + i.size()
		cur_coords.y = cur_coords.y - 1
		i.reverse()
	gridspace.reverse()
	
	for i in active_hovered:
		hovermap.set_cell(i,-1)
	for i in map_coordinates:
		if buildmap.get_cell_source_id(i) != -1:
			if buildmap.get_cell_tile_data(i).get_custom_data('Buildable') == true:
				hovermap.set_cell(i, 0, Vector2i(1,0))
			else:
				hovermap.set_cell(i, 0, Vector2i(0,0))
				validity_count = validity_count + 1
		else:
			hovermap.set_cell(i, 0, Vector2i(0,0))
			validity_count = validity_count + 1
		hovered_cells.append(i)
	if validity_count == 0:
		valid_placement = true
	return(hovered_cells)
		
func building_start(building: Dictionary) -> void:
	current_building = building
	build_mode = true
	pass

func complete_building() -> void:
	if current_building == null:
		print("No building? How did we get here?")
		get_tree().quit()
	var placement_spot_tile = active_hovered[-1]
	var placement_spot_local = hovermap.map_to_local(placement_spot_tile)
	placement_spot_local.x = placement_spot_local.x - hovermap.tile_set.tile_size.x/2
	placement_spot_local.y = placement_spot_local.y - hovermap.tile_set.tile_size.y/2
	var build_scene = load("res://Scenes/building_scenes/"+current_building["building_scene"]).instantiate()
	build_scene.position = placement_spot_local
	build_scene.y_sort_enabled = true
	add_child(build_scene)
	
	for i in active_hovered:
		buildmap.set_cell(i,0,Vector2i(current_building["tile_id_coords"][0],current_building["tile_id_coords"][1]))
	
	BuildEnv.stop_buildin.emit() #returns user back to build menu
	#building_stop() #Lets player keep building the same building
	

func building_stop() -> void:
	for i in active_hovered:
		hovermap.set_cell(i,-1)
	active_hovered = []
	build_mode = false
	if valid_placement && placed:
		BuildEnv.remove_blueprint.emit()
	placed = false
	
	pass
		
