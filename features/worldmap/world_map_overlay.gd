extends Control
class_name WorldMapOverlay

signal close_requested

@onready var close_button: Button = %CloseButton
@onready var objective_text: Label = %ObjectiveText

@onready var map_sub_viewport: SubViewport = %MapSubViewport

@export_range(0.05, 4.0, 0.01) var fallback_zoom_scale: float = 0.6

var _player: Node2D
var _last_objective_text: String = ""
var _map_camera: Camera2D
var _is_bounds_mode: bool = false

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	_setup_map_camera()

	if close_button != null:
		close_button.pressed.connect(_on_close_button_pressed)

func open() -> void:
	visible = true
	_set_player_reference()
	_fit_map_to_current_level()
	_refresh_objective_text()
	if close_button != null:
		close_button.grab_focus()

func close() -> void:
	visible = false

func _process(_delta: float) -> void:
	if not visible:
		return

	if visible:
		_refresh_objective_text()

	if _player == null:
		_set_player_reference()

	if not _is_bounds_mode and _player != null and _map_camera != null:
		_map_camera.global_position = _player.global_position

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("world_map") or event.is_action_pressed("ui_cancel"):
		emit_signal("close_requested")
		get_viewport().set_input_as_handled()

func _on_close_button_pressed() -> void:
	emit_signal("close_requested")

func _set_player_reference() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0] as Node2D

func _refresh_objective_text() -> void:
	var objective := ObjectiveManager.get_objective().strip_edges()
	var next_text := "No active objective" if objective.is_empty() else "Objective: %s" % objective
	if next_text == _last_objective_text:
		return

	_last_objective_text = next_text
	objective_text.text = next_text

func _setup_map_camera() -> void:
	map_sub_viewport.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	map_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	map_sub_viewport.world_2d = get_tree().root.world_2d

	_map_camera = Camera2D.new()
	_map_camera.enabled = true
	_map_camera.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	map_sub_viewport.add_child(_map_camera)

func _fit_map_to_current_level() -> void:
	if _map_camera == null:
		return

	var level_bounds := _get_current_level_bounds()
	if level_bounds.size.x > 1.0 and level_bounds.size.y > 1.0:
		_is_bounds_mode = true
		_map_camera.global_position = level_bounds.position + level_bounds.size * 0.5

		var viewport_size := Vector2(map_sub_viewport.size)
		var fit_x: float = viewport_size.x / maxf(level_bounds.size.x, 1.0)
		var fit_y: float = viewport_size.y / maxf(level_bounds.size.y, 1.0)
		var zoom_value: float = minf(fit_x, fit_y) * 0.92
		zoom_value = clamp(zoom_value, 0.05, 4.0)
		_map_camera.zoom = Vector2(zoom_value, zoom_value)
		return

	_is_bounds_mode = false
	_map_camera.zoom = Vector2(fallback_zoom_scale, fallback_zoom_scale)
	if _player != null:
		_map_camera.global_position = _player.global_position

func _get_current_level_bounds() -> Rect2:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return Rect2()

	var level_holder := current_scene.get_node_or_null("LevelHolder")
	if level_holder == null or level_holder.get_child_count() == 0:
		return Rect2()

	var level_root := level_holder.get_child(0)
	var bounds_state := {
		"found": false,
		"min": Vector2.ZERO,
		"max": Vector2.ZERO
	}
	_collect_tilemap_bounds(level_root, bounds_state)

	if not bounds_state["found"]:
		return Rect2()

	var min_pos: Vector2 = bounds_state["min"]
	var max_pos: Vector2 = bounds_state["max"]
	return Rect2(min_pos, max_pos - min_pos)

func _collect_tilemap_bounds(node: Node, bounds_state: Dictionary) -> void:
	if node is TileMapLayer:
		var layer := node as TileMapLayer
		var used_rect := layer.get_used_rect()
		if used_rect.size != Vector2i.ZERO:
			var tile_size := Vector2(16.0, 16.0)
			if layer.tile_set != null:
				tile_size = Vector2(layer.tile_set.tile_size)

			var local_origin := Vector2(used_rect.position) * tile_size
			var local_size := Vector2(used_rect.size) * tile_size
			var points := [
				local_origin,
				local_origin + Vector2(local_size.x, 0.0),
				local_origin + Vector2(0.0, local_size.y),
				local_origin + local_size
			]

			for point in points:
				var global_point := layer.to_global(point)
				if not bounds_state["found"]:
					bounds_state["min"] = global_point
					bounds_state["max"] = global_point
					bounds_state["found"] = true
				else:
					var min_pos: Vector2 = bounds_state["min"]
					var max_pos: Vector2 = bounds_state["max"]
					min_pos.x = min(min_pos.x, global_point.x)
					min_pos.y = min(min_pos.y, global_point.y)
					max_pos.x = max(max_pos.x, global_point.x)
					max_pos.y = max(max_pos.y, global_point.y)
					bounds_state["min"] = min_pos
					bounds_state["max"] = max_pos

	for child in node.get_children():
		_collect_tilemap_bounds(child, bounds_state)
