extends Control
class_name WorldMapOverlay

const PLAYER_MARKER_TEXTURE_A = preload("res://assets/sprites/maps/yellow-1.png")
const PLAYER_MARKER_TEXTURE_B = preload("res://assets/sprites/maps/yellow-2.png")

signal close_requested

@onready var close_button: Button = get_node_or_null("Panel/MarginContainer/VBoxContainer/CloseButton")
@onready var player_marker: TextureRect = %PlayerMarker

@onready var map_area: Control = %MapArea
@onready var map_sub_viewport: SubViewport = %MapSubViewport
@onready var map_viewport_container: SubViewportContainer = get_node_or_null("Panel/MarginContainer/VBoxContainer/MapArea/MapViewportContainer")

@export_range(0.05, 4.0, 0.01) var fallback_zoom_scale: float = 0.6
@export_range(0.1, 3.0, 0.01) var bounds_zoom_multiplier: float = 1.25
@export var player_marker_size: Vector2 = Vector2(28.0, 28.0)
@export var player_marker_blink_interval: float = 0.2

var _player: Node2D
var _map_camera: Camera2D
var _is_bounds_mode: bool = false
var _current_level_bounds: Rect2 = Rect2()
var _player_marker_elapsed: float = 0.0
var _player_marker_texture_index: int = 0
var _player_was_visible: bool = true

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	_setup_map_camera()

	if close_button != null:
		close_button.pressed.connect(_on_close_button_pressed)

func open() -> void:
	visible = true
	_set_player_reference()
	_store_and_hide_player()
	_reset_player_marker_animation()
	_fit_map_to_current_level()
	_update_player_marker(0.0)
	call_deferred("_refit_map_next_frame")
	if close_button != null and close_button.visible:
		close_button.grab_focus()

func close() -> void:
	_restore_player_visibility()
	visible = false

func _process(_delta: float) -> void:
	if not visible:
		return

	if _player == null:
		_set_player_reference()

	_update_player_marker(_delta)

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

func _store_and_hide_player() -> void:
	if _player == null or not is_instance_valid(_player):
		return

	_player_was_visible = _player.visible
	_player.visible = false

func _restore_player_visibility() -> void:
	if _player != null and is_instance_valid(_player):
		_player.visible = _player_was_visible

func _reset_player_marker_animation() -> void:
	_player_marker_elapsed = 0.0
	_player_marker_texture_index = 0
	_apply_player_marker_texture()

func _apply_player_marker_texture() -> void:
	if player_marker == null:
		return

	player_marker.texture = PLAYER_MARKER_TEXTURE_A if _player_marker_texture_index == 0 else PLAYER_MARKER_TEXTURE_B
	player_marker.custom_minimum_size = player_marker_size
	player_marker.size = player_marker_size

func _update_player_marker(delta: float) -> void:
	if player_marker == null or not visible:
		return

	if _player == null or _current_level_bounds.size.x <= 1.0 or _current_level_bounds.size.y <= 1.0:
		if map_viewport_container != null:
			player_marker.position = map_viewport_container.position + (map_viewport_container.size - player_marker.size) * 0.5
		elif map_area != null:
			player_marker.position = (map_area.size - player_marker.size) * 0.5
		else:
			player_marker.position = Vector2.ZERO
		player_marker.visible = _player != null
		return

	if player_marker_blink_interval > 0.0:
		_player_marker_elapsed += delta
		if _player_marker_elapsed >= player_marker_blink_interval:
			_player_marker_elapsed = fmod(_player_marker_elapsed, player_marker_blink_interval)
			_player_marker_texture_index = 1 - _player_marker_texture_index
			_apply_player_marker_texture()

	var viewport_origin := Vector2.ZERO
	var viewport_size := Vector2.ZERO
	if map_viewport_container != null:
		viewport_origin = map_viewport_container.position
		viewport_size = map_viewport_container.size
	elif map_area != null:
		viewport_origin = Vector2.ZERO
		viewport_size = map_area.size

	if (viewport_size.x <= 1.0 or viewport_size.y <= 1.0) and map_sub_viewport != null:
		viewport_size = Vector2(map_sub_viewport.size)
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		viewport_size = get_viewport_rect().size

	if map_sub_viewport != null:
		var viewport_point := map_sub_viewport.get_canvas_transform() * _player.global_position
		player_marker.position = viewport_origin + viewport_point - player_marker.size * 0.5
	else:
		var normalized := (_player.global_position - _current_level_bounds.position) / _current_level_bounds.size
		normalized.x = clamp(normalized.x, 0.0, 1.0)
		normalized.y = clamp(normalized.y, 0.0, 1.0)
		player_marker.position = viewport_origin + normalized * viewport_size - player_marker.size * 0.5

	player_marker.visible = true

func _setup_map_camera() -> void:
	if map_sub_viewport == null:
		return

	map_sub_viewport.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	map_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	map_sub_viewport.world_2d = get_tree().root.world_2d

	_map_camera = Camera2D.new()
	_map_camera.enabled = true
	_map_camera.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	map_sub_viewport.add_child(_map_camera)

func _fit_map_to_current_level() -> void:
	if _map_camera == null or map_sub_viewport == null:
		return

	_current_level_bounds = _get_current_level_bounds()
	if _current_level_bounds.size.x > 1.0 and _current_level_bounds.size.y > 1.0:
		_is_bounds_mode = true
		_map_camera.global_position = _current_level_bounds.position + _current_level_bounds.size * 0.5

		var viewport_size := Vector2(map_sub_viewport.size)
		if map_viewport_container != null and map_viewport_container.size.x > 1.0 and map_viewport_container.size.y > 1.0:
			viewport_size = map_viewport_container.size

		if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
			viewport_size = get_viewport_rect().size

		map_sub_viewport.size = Vector2i(int(maxf(viewport_size.x, 1.0)), int(maxf(viewport_size.y, 1.0)))

		var fit_x: float = viewport_size.x / maxf(_current_level_bounds.size.x, 1.0)
		var fit_y: float = viewport_size.y / maxf(_current_level_bounds.size.y, 1.0)
		var zoom_value: float = minf(fit_x, fit_y) * 0.92 * bounds_zoom_multiplier
		zoom_value = clamp(zoom_value, 0.05, 4.0)
		_map_camera.zoom = Vector2(zoom_value, zoom_value)
		_update_player_marker(0.0)
		return

	_is_bounds_mode = false
	_current_level_bounds = Rect2()
	_map_camera.zoom = Vector2(fallback_zoom_scale, fallback_zoom_scale)
	if _player != null:
		_map_camera.global_position = _player.global_position

func _refit_map_next_frame() -> void:
	if not visible:
		return

	await get_tree().process_frame
	if not visible:
		return

	_fit_map_to_current_level()
	_update_player_marker(0.0)

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
