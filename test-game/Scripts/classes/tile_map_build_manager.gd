##A class for managing tilemaps underneath for build mode. Enables hovered tiles and editing of tiles.
class_name build_manager extends Node2D

@export var tilemaps: Array[Node] ##Array of tilemaps to be affected. Should be ordered in a stack, 0 is the highest.
@export var hovermap: Node ##The tilemap setup for hover selected tiles. Make sure that the icon you use for hovering is on source ID 0 and atlas coordinates (0,0) in the tile set for this map
@export var buildmap: Node ##The building tilemap

var active_hovered = []
var build_mode = false

func _ready() -> void:
	pass

func _input(event):
	# Mouse in viewport coordinates.
	if Input.is_action_just_pressed("build_swap"):
		if BuildEnvironment.enabled == true:
			for i in active_hovered:
				hovermap.set_cell(i,-1)
			active_hovered = []
			build_mode = not build_mode

		
	if event is InputEventMouseButton && event.is_pressed() == true && event.get_button_index() == 1:
		if build_mode:
			active_hovered = hover_mark([get_global_mouse_position()])

func hover_mark(coordinates: Array[Vector2]) -> Array[Vector2]:
	var hovered_cells: Array[Vector2] = []
	#var old_hovered = hovermap.get_used_cells_by_id(0, Vector2i(0,0))
	for i in active_hovered:
		hovermap.set_cell(i,-1)
	for i in coordinates:
		var hover_target = hovermap.local_to_map(i)
		if buildmap.get_cell_source_id(hover_target) != -1:
			if buildmap.get_cell_tile_data(hover_target).get_custom_data('Buildable') == true:
				hovermap.set_cell(hover_target, 0, Vector2i(1,0))
		else:
			hovermap.set_cell(hover_target, 0, Vector2i(0,0))
		hovered_cells.append(hover_target)
	return(hovered_cells)
		
		
		
