@tool
extends Node2D
class_name ProceduralRoomCellMarker

@export var cell: Vector2i = Vector2i.ZERO
@export var grid_cell_size: Vector2 = Vector2(160.0, 160.0)
@export var debug_cell_size: Vector2 = Vector2(160.0, 160.0)
@export var debug_fill_color: Color = Color(0.29, 0.56, 0.82, 0.45)
@export var debug_outline_color: Color = Color(0.45, 0.76, 1.0, 0.95)

var _is_syncing := false

func _enter_tree() -> void:
	set_process(true)
	_sync_position_from_cell()
	queue_redraw()

func _ready() -> void:
	_sync_position_from_cell()
	queue_redraw()

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return

	_sync_position_from_cell()
	queue_redraw()

func _draw() -> void:

	var rect := Rect2(-(_get_resolved_cell_size() * 0.5), _get_resolved_cell_size())
	draw_rect(rect, debug_fill_color, true)
	draw_rect(rect, debug_outline_color, false, 4.0)
	draw_line(rect.position, rect.position + rect.size, debug_outline_color, 2.0)
	draw_line(
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + Vector2(0.0, rect.size.y),
		debug_outline_color,
		2.0
	)
	draw_circle(Vector2.ZERO, 6.0, debug_outline_color)

func sync_visual(grid_size: Vector2, preview_size: Vector2, fill_color: Color, outline_color: Color, show_preview: bool) -> void:
	var resolved_grid_size := _resolve_size(grid_size)
	var grid_size_changed := resolved_grid_size != _resolve_size(grid_cell_size)
	grid_cell_size = resolved_grid_size
	debug_cell_size = _resolve_size(preview_size)
	debug_fill_color = fill_color
	debug_outline_color = outline_color
	if grid_size_changed:
		_sync_position_from_cell()
	queue_redraw()

func _sync_position_from_cell() -> void:
	if _is_syncing:
		return

	_is_syncing = true
	position = (Vector2(cell.x, cell.y) + Vector2(0.5, 0.5)) * _get_resolved_grid_size()
	_is_syncing = false

func _sync_cell_from_position() -> void:
	if _is_syncing:
		return

	var resolved_cell_size := _get_resolved_grid_size()
	var snapped_cell := Vector2i(
		int(round((position.x / resolved_cell_size.x) - 0.5)),
		int(round((position.y / resolved_cell_size.y) - 0.5))
	)

	_is_syncing = true
	position = (Vector2(snapped_cell.x, snapped_cell.y) + Vector2(0.5, 0.5)) * resolved_cell_size
	_is_syncing = false

func _get_resolved_cell_size() -> Vector2:
	return _resolve_size(debug_cell_size)

func _get_resolved_grid_size() -> Vector2:
	return _resolve_size(grid_cell_size)

func _resolve_size(raw_size: Variant) -> Vector2:
	if not (raw_size is Vector2):
		return Vector2(160.0, 160.0)
	return Vector2(maxf(raw_size.x, 8.0), maxf(raw_size.y, 8.0))
