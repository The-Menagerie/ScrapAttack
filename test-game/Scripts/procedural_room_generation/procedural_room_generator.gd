extends Node2D
class_name ProceduralRoomGenerator

@export var start_room_scene: PackedScene
@export var required_room_scenes: Array[PackedScene] = []
@export var room_scenes: Array[PackedScene] = []
@export var target_room_count: int = 10
@export var max_failed_expansions: int = 64
@export var layout_cell_size: Vector2 = Vector2(160.0, 160.0)
@export var regenerate_on_ready: bool = true
@export var room_container_path: NodePath = NodePath("Rooms")
@export var player_path: NodePath
@export var random_seed: int = 0

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	if regenerate_on_ready:
		generate_layout()

func generate_layout() -> void:
	var room_container := get_node_or_null(room_container_path) as Node2D
	if room_container == null:
		push_warning("ProceduralRoomGenerator requires a Node2D room container.")
		return

	for child in room_container.get_children():
		child.queue_free()

	var start_template := _build_room_template(start_room_scene)
	if start_template.is_empty():
		push_warning("Start room scene must inherit ProceduralRoom.")
		return

	var all_templates: Array[Dictionary] = []
	var required_templates: Array[Dictionary] = []
	for room_scene in required_room_scenes:
		var template := _build_room_template(room_scene)
		if template.is_empty():
			continue
		required_templates.append(template)

	for room_scene in room_scenes:
		var template := _build_room_template(room_scene)
		if template.is_empty():
			continue
		all_templates.append(template)

	if all_templates.is_empty():
		all_templates.append(start_template)

	_setup_rng()

	var placements: Array[Dictionary] = []
	var occupied_cells: Dictionary = {}
	var open_doors: Array[Dictionary] = []

	var start_placement := {
		"template": start_template,
		"origin": Vector2i.ZERO
	}
	placements.append(start_placement)
	_mark_occupied_cells(occupied_cells, start_template, Vector2i.ZERO)
	open_doors.append_array(_collect_open_doors(start_template, Vector2i.ZERO, occupied_cells, -1))

	_shuffle_array(required_templates)
	_fill_remaining_templates(all_templates, required_templates, placements, occupied_cells, open_doors)

	_spawn_layout(room_container, placements)

func _spawn_layout(room_container: Node2D, placements: Array[Dictionary]) -> void:
	for placement in placements:
		var template: Dictionary = placement["template"]
		var room_scene := template["scene"] as PackedScene
		var room_node := room_scene.instantiate() as Node2D
		if room_node == null:
			continue

		room_container.add_child(room_node)
		var room_origin: Vector2i = placement["origin"]
		room_node.position = Vector2(room_origin.x, room_origin.y) * layout_cell_size

		var procedural_room := room_node as ProceduralRoom
		if procedural_room != null:
			procedural_room.debug_cell_size = layout_cell_size
			procedural_room.sync_marker_debug_cell_size()

	if placements.is_empty():
		return

	var player := get_node_or_null(player_path) as Node2D
	if player == null:
		return

	var start_room_node := room_container.get_child(0) as ProceduralRoom
	if start_room_node == null:
		return

	player.global_position = start_room_node.global_position + start_room_node.get_spawn_position(layout_cell_size)

func _build_room_template(room_scene: PackedScene) -> Dictionary:
	if room_scene == null:
		return {}

	var room_instance := room_scene.instantiate()
	var procedural_room := room_instance as ProceduralRoom
	if procedural_room == null:
		if room_instance != null:
			room_instance.free()
		return {}

	var template := {
		"scene": room_scene,
		"room_id": procedural_room.room_id if not procedural_room.room_id.is_empty() else room_instance.name,
		"footprint": procedural_room.get_footprint_cells(),
		"doors": _serialize_doors(procedural_room.get_doorways())
	}
	room_instance.free()
	return template

func _fill_remaining_templates(
	all_templates: Array[Dictionary],
	required_templates: Array[Dictionary],
	placements: Array[Dictionary],
	occupied_cells: Dictionary,
	open_doors: Array[Dictionary]
) -> void:
	var failed_expansions := 0
	while placements.size() < max(target_room_count, 1) and not open_doors.is_empty() and failed_expansions < max_failed_expansions:
		var frontier_index := _rng.randi_range(0, open_doors.size() - 1)
		var frontier := open_doors
		var remaining_slots: int = max(target_room_count, 1) - placements.size()
		var place_required_now: bool = _should_place_required_room(required_templates.size(), remaining_slots)
		print(place_required_now)
		var placement: Dictionary = {}

		if place_required_now and not required_templates.is_empty():
			var required_template: Dictionary = required_templates[0]
			placement = _try_place_room(frontier, [required_template], occupied_cells, frontier_index)
			if placement.is_empty():
				push_warning("ProceduralRoomGenerator could not place required room at this branch: %s" % String(required_template.get("room_id", "unnamed_room")))
			else:
				required_templates.remove_at(0)

		if placement.is_empty():
			placement = _try_place_room(frontier, all_templates, occupied_cells, frontier_index)

		if placement.is_empty():
			open_doors.remove_at(frontier_index)
			failed_expansions += 1
			continue

		failed_expansions = 0
		_commit_room_placement(placement, placements, occupied_cells, open_doors)

	if not required_templates.is_empty():
		push_warning("ProceduralRoomGenerator finished without placing every required room.")

func _commit_room_placement(
	placement: Dictionary,
	placements: Array[Dictionary],
	occupied_cells: Dictionary,
	open_doors: Array[Dictionary]
) -> void:
	var connected_frontier_index := int(placement["frontier_index"])
	if connected_frontier_index >= 0 and connected_frontier_index < open_doors.size():
		open_doors.remove_at(connected_frontier_index)

	placements.append(placement)
	_mark_occupied_cells(occupied_cells, placement["template"], placement["origin"])

	var new_placement_index := placements.size() - 1
	open_doors.append_array(
		_collect_open_doors(
			placement["template"],
			placement["origin"],
			occupied_cells,
			int(placement["connected_door_index"]),
			new_placement_index
		)
	)

func _should_place_required_room(required_count: int, remaining_slots: int) -> bool:
	if required_count <= 0 or remaining_slots <= 0:
		return false

	if required_count >= remaining_slots:
		return true

	return _rng.randf() < (float(required_count) / float(remaining_slots))

func _serialize_doors(raw_doors: Array) -> Array[Dictionary]:
	var serialized: Array[Dictionary] = []
	for doorway in raw_doors:
		var typed_doorway := doorway as ProceduralRoomDoor
		if typed_doorway == null:
			continue
		serialized.append({
			"cell": typed_doorway.cell,
			"direction": typed_doorway.get_cardinal_direction()
		})
	return serialized

func _mark_occupied_cells(occupied_cells: Dictionary, template: Dictionary, origin: Vector2i) -> void:
	for local_cell: Vector2i in template["footprint"]:
		occupied_cells[origin + local_cell] = true

func _collect_open_doors(
	template: Dictionary,
	origin: Vector2i,
	occupied_cells: Dictionary,
	connected_door_index: int,
	placement_index: int = 0
) -> Array[Dictionary]:
	var doors: Array[Dictionary] = []
	for door_index in range(template["doors"].size()):
		if door_index == connected_door_index:
			continue

		var door: Dictionary = template["doors"][door_index]
		var world_cell: Vector2i = origin + door["cell"]
		var neighbor_cell: Vector2i = world_cell + door["direction"]
		if occupied_cells.has(neighbor_cell):
			continue

		doors.append({
			"placement_index": placement_index,
			"door_index": door_index,
			"world_cell": world_cell,
			"direction": door["direction"]
		})
	return doors

func _try_place_room(
	frontier: Array[Dictionary],
	templates: Array[Dictionary],
	occupied_cells: Dictionary,
	frontier_index: int = -1
) -> Dictionary:
	var shuffled_templates := templates.duplicate()
	_shuffle_array(shuffled_templates)
	_shuffle_array(frontier)

	for template in shuffled_templates:
		var candidate_doors: Array[Dictionary] = template["doors"].duplicate()
		_shuffle_array(candidate_doors)

		for candidate_door in candidate_doors:
			for i in frontier:
				if candidate_door["direction"] != -i["direction"]:
					print("no proper door direction")
					continue

				var candidate_origin: Vector2i = (i["world_cell"] + i["direction"]) - candidate_door["cell"]
				if _can_place_template(template, candidate_origin, occupied_cells):
					var frontier_ind = frontier.find(i)
					return {
						"template": template,
						"origin": candidate_origin,
						"connected_door_index": template["doors"].find(candidate_door),
						"frontier_index": frontier_ind
				}

	return {}

func _can_place_template(template: Dictionary, origin: Vector2i, occupied_cells: Dictionary) -> bool:
	for local_cell: Vector2i in template["footprint"]:
		if occupied_cells.has(origin + local_cell):
			print("sorry, this don't work")
			return false
	return true

func _shuffle_array(values: Array) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var temp = values[i]
		values[i] = values[j]
		values[j] = temp

func _setup_rng() -> void:
	if random_seed == 0:
		_rng.randomize()
		return

	_rng.seed = random_seed
