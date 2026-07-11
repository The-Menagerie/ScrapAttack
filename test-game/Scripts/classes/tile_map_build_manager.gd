##A class for managing tilemaps underneath for build mode. Enables hovered tiles and editing of tiles.
class_name build_manager extends Node2D

@export var tilemaps: Array[Node] ##Array of tilemaps to be affected. Should be ordered in a stack, 0 is the highest.
@export var hovermap: Node ##The tilemap setup for hover selected tiles. Make sure that the icon you use for hovering is on source ID 0 and atlas coordinates (0,0) in the tile set for this map

func _ready() -> void:
	pass

func _input(event):
	# Mouse in viewport coordinates.
	if event is InputEventMouseButton && event.is_pressed() == true && event.get_button_index() == 1:
		hover_mark([event.position])

func hover_mark(coordinates: Array[Vector2]):
	var old_hovered = hovermap.get_used_cells_by_id(0, Vector2i(0,0))
	for i in old_hovered:
		hovermap.set_cell(i,-1)
	for i in coordinates:
		var hover_target = hovermap.local_to_map(i)
		hovermap.set_cell(hover_target, 0, Vector2i(0,0))
