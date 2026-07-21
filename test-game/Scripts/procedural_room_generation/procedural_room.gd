@tool
extends Node2D
class_name ProceduralRoom

@export var room_id: String = ""
@export var footprint_cells: Array[Vector2i] = [Vector2i.ZERO]
@export var doorways: Array[Resource] = []
@export var grid_cell_size: Vector2 = Vector2(160.0, 160.0)
@export var debug_cell_size: Vector2 = Vector2(160.0, 160.0)
@export var debug_fill_color: Color = Color(0.29, 0.56, 0.82, 0.45)
@export var debug_outline_color: Color = Color(0.45, 0.76, 1.0, 0.95)
@export var show_footprint_preview: bool = true
@export var show_doorway_preview: bool = true
@export var player_spawn_cell: Vector2i = Vector2i.ZERO

func _enter_tree() -> void:
	set_process(true)
	sync_marker_debug_cell_size()
	queue_redraw()

func _ready() -> void:
	sync_marker_debug_cell_size()
	queue_redraw()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		sync_marker_debug_cell_size()
		queue_redraw()

func _draw() -> void:
	var cells := get_footprint_cells()
	var resolved_cell_size := _get_resolved_preview_cell_size()
	if not _has_cell_markers() and show_footprint_preview:
		for cell in cells:
			var rect := Rect2(Vector2(cell.x, cell.y) * resolved_cell_size, resolved_cell_size)
			draw_rect(rect, debug_fill_color, true)
			draw_rect(rect, debug_outline_color, false)
			draw_line(rect.position, rect.position + rect.size, debug_outline_color, 2.0)
			draw_line(
				rect.position + Vector2(rect.size.x, 0.0),
				rect.position + Vector2(0.0, rect.size.y),
				debug_outline_color,
				2.0
			)
			draw_circle(rect.get_center(), 6.0, debug_outline_color)

	if not _has_door_markers() and show_doorway_preview:
		for doorway in get_doorways():
			var cell_center := (Vector2(doorway.cell.x, doorway.cell.y) + Vector2(0.5, 0.5)) * resolved_cell_size
			var half_step := Vector2(doorway.direction.x, doorway.direction.y) * (resolved_cell_size * 0.5)
			var outer_point := cell_center + half_step
			var inner_point := cell_center + (half_step * 0.35)
			draw_line(inner_point, outer_point, Color.WHITE, 4.0)
			draw_circle(outer_point, 6.0, Color(1.0, 1.0, 1.0, 0.85))

func get_footprint_cells() -> Array[Vector2i]:
	var marker_cells := _get_marker_cells()
	if not marker_cells.is_empty():
		return marker_cells

	return _sanitize_cells(footprint_cells)

func get_doorways() -> Array:
	var marker_doors := _get_marker_doors()
	if not marker_doors.is_empty():
		return marker_doors

	var cleaned: Array = []
	for doorway_resource in doorways:
		var doorway := doorway_resource as ProceduralRoomDoor
		if doorway == null:
			continue
		cleaned.append(doorway)
	return cleaned

func sync_marker_debug_cell_size() -> void:
	var resolved_grid_cell_size := _get_resolved_grid_cell_size()
	var resolved_preview_cell_size := _get_resolved_preview_cell_size()
	for child in get_children():
		var cell_marker := child as ProceduralRoomCellMarker
		if cell_marker != null:
			cell_marker.sync_visual(
				resolved_grid_cell_size,
				resolved_preview_cell_size,
				debug_fill_color,
				debug_outline_color,
				show_footprint_preview
			)
			continue

		var marker := child as ProceduralRoomDoorwayMarker
		if marker == null:
			continue
		marker.sync_visual(resolved_grid_cell_size, resolved_preview_cell_size, show_doorway_preview)

func get_spawn_position(cell_size: Vector2) -> Vector2:
	return (Vector2(player_spawn_cell.x, player_spawn_cell.y) + Vector2(0.5, 0.5)) * cell_size

func _sanitize_cells(raw_cells: Array[Vector2i]) -> Array[Vector2i]:
	var unique_cells: Dictionary = {}
	for cell in raw_cells:
		unique_cells[cell] = true

	if unique_cells.is_empty():
		unique_cells[Vector2i.ZERO] = true

	var cleaned: Array[Vector2i] = []
	for cell in unique_cells.keys():
		cleaned.append(cell)

	cleaned.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	)
	return cleaned

func _get_marker_doors() -> Array:
	var marker_doors: Array = []
	for child in get_children():
		var marker := child as ProceduralRoomDoorwayMarker
		if marker == null:
			continue
		marker_doors.append(marker.to_room_door())
	return marker_doors

func _get_marker_cells() -> Array[Vector2i]:
	var marker_cells: Array[Vector2i] = []
	for child in get_children():
		var marker := child as ProceduralRoomCellMarker
		if marker == null:
			continue
		marker_cells.append(marker.cell)
	return _sanitize_cells(marker_cells)

func _has_cell_markers() -> bool:
	for child in get_children():
		if child is ProceduralRoomCellMarker:
			return true
	return false

func _has_door_markers() -> bool:
	for child in get_children():
		if child is ProceduralRoomDoorwayMarker:
			return true
	return false

func _get_resolved_grid_cell_size() -> Vector2:
	return Vector2(maxf(grid_cell_size.x, 8.0), maxf(grid_cell_size.y, 8.0))

func _get_resolved_preview_cell_size() -> Vector2:
	return Vector2(maxf(debug_cell_size.x, 8.0), maxf(debug_cell_size.y, 8.0))
