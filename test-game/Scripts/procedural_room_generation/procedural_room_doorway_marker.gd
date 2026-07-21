@tool
extends Node2D
class_name ProceduralRoomDoorwayMarker

@export var cell: Vector2i = Vector2i.ZERO
@export var direction: Vector2i = Vector2i.RIGHT
@export var grid_cell_size: Vector2 = Vector2(160.0, 160.0)
@export var debug_cell_size: Vector2 = Vector2(160.0, 160.0)
@export var debug_color: Color = Color(1.0, 1.0, 1.0, 0.9)
@export var preview_enabled: bool = true

var _is_syncing := false

func _enter_tree() -> void:
	set_process(true)
	_sync_position_from_data()
	queue_redraw()

func _ready() -> void:
	_sync_position_from_data()
	queue_redraw()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_sync_position_from_data()
		queue_redraw()

func _draw() -> void:
	if not preview_enabled:
		return

	var resolved_cell_size := Vector2(maxf(debug_cell_size.x, 8.0), maxf(debug_cell_size.y, 8.0))
	var resolved_direction := _get_cardinal_direction(direction)
	var half_step := Vector2(resolved_direction.x, resolved_direction.y) * (resolved_cell_size * 0.5)
	var outer_point := Vector2.ZERO
	var inner_point := -half_step * 0.65
	draw_line(inner_point, outer_point, debug_color, 4.0)
	draw_circle(outer_point, 6.0, debug_color)

func sync_visual(grid_size: Vector2, preview_size: Vector2, show_preview: bool) -> void:
	var resolved_grid_size := _resolve_size(grid_size)
	var grid_size_changed := resolved_grid_size != _resolve_size(grid_cell_size)
	grid_cell_size = resolved_grid_size
	debug_cell_size = _resolve_size(preview_size)
	preview_enabled = show_preview
	if grid_size_changed:
		_sync_position_from_data()
	queue_redraw()

func to_room_door() -> ProceduralRoomDoor:
	var doorway := ProceduralRoomDoor.new()
	doorway.cell = cell
	doorway.direction = _get_cardinal_direction(direction)
	return doorway

func _sync_position_from_data() -> void:
	if _is_syncing:
		return

	var resolved_cell_size := _get_resolved_grid_size()
	var resolved_direction := _get_cardinal_direction(direction)
	var cell_center := (Vector2(cell.x, cell.y) + Vector2(0.5, 0.5)) * resolved_cell_size
	var half_step := Vector2(resolved_direction.x, resolved_direction.y) * (resolved_cell_size * 0.5)

	_is_syncing = true
	position = cell_center + half_step
	_is_syncing = false

func _sync_data_from_position() -> void:
	if _is_syncing:
		return

	var resolved_cell_size := _get_resolved_grid_size()
	var resolved_direction := _get_cardinal_direction(direction)
	var half_step := Vector2(resolved_direction.x, resolved_direction.y) * (resolved_cell_size * 0.5)
	var cell_center := position - half_step
	var snapped_cell := Vector2i(
		int(round((cell_center.x / resolved_cell_size.x) - 0.5)),
		int(round((cell_center.y / resolved_cell_size.y) - 0.5))
	)

	_is_syncing = true
	cell = snapped_cell
	position = (Vector2(snapped_cell.x, snapped_cell.y) + Vector2(0.5, 0.5)) * resolved_cell_size + half_step
	_is_syncing = false

func _get_cardinal_direction(raw_direction: Vector2i) -> Vector2i:
	if raw_direction == Vector2i.ZERO:
		return Vector2i.RIGHT

	if abs(raw_direction.x) >= abs(raw_direction.y):
		return Vector2i(_sign_int(raw_direction.x), 0)

	return Vector2i(0, _sign_int(raw_direction.y))

func _sign_int(value: int) -> int:
	if value > 0:
		return 1
	if value < 0:
		return -1
	return 0

func _get_resolved_cell_size() -> Vector2:
	return _resolve_size(debug_cell_size)

func _get_resolved_grid_size() -> Vector2:
	return _resolve_size(grid_cell_size)

func _resolve_size(raw_size: Vector2) -> Vector2:
	return Vector2(maxf(raw_size.x, 8.0), maxf(raw_size.y, 8.0))
