extends Node2D


enum PatrolAnchor {
	MID_RIGHT,
	TOP_RIGHT,
	BOTTOM_RIGHT,
	BOTTOM_LEFT,
	TOP_LEFT,
	MID_LEFT,
}

@export var camera_path: NodePath = NodePath("../../Player/Camera2D")
@export var swim_speed: float = 140.0
@export var dive_speed_multiplier: float = 1.8
@export var arrival_distance: float = 18.0
@export var border_padding: Vector2 = Vector2(88.0, 72.0)
@export var mid_anchor_lift: float = 22.0
@export var top_anchor_lift: float = 30.0
@export var use_randomized_path: bool = false
@export var reshuffle_each_loop: bool = true

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _camera: Camera2D
var _anchors: Array[PatrolAnchor] = []
var _anchor_index: int = 0
var _previous_anchor: PatrolAnchor = PatrolAnchor.MID_RIGHT
var _last_camera_center: Vector2 = Vector2.ZERO
var _has_last_camera_center: bool = false


func _ready() -> void:
	_camera = _resolve_camera()
	_build_anchor_path()
	if _camera == null:
		push_warning("WaterSerpent: Camera2D not found. The serpent will keep trying to bind in _process.")
		return

	_update_dive_state(_anchors[_anchor_index])
	_last_camera_center = _camera.get_screen_center_position()
	_has_last_camera_center = true


func _process(delta: float) -> void:
	if _camera == null:
		_camera = _resolve_camera()
		if _camera == null:
			return
		_last_camera_center = _camera.get_screen_center_position()
		_has_last_camera_center = true

	if _anchors.is_empty():
		return

	var camera_center: Vector2 = _camera.get_screen_center_position()
	if _has_last_camera_center:
		# Keep serpent anchored to the camera space while still swimming between anchors.
		global_position += camera_center - _last_camera_center
	_last_camera_center = camera_center
	_has_last_camera_center = true

	var target_anchor: PatrolAnchor = _anchors[_anchor_index]
	var target_position: Vector2 = _get_anchor_world_position(target_anchor)
	var move_speed: float = swim_speed * (dive_speed_multiplier if _is_dive_segment(_previous_anchor, target_anchor) else 1.0)
	global_position = global_position.move_toward(target_position, move_speed * delta)

	if global_position.distance_to(target_position) <= arrival_distance:
		_go_to_next_anchor()
		_update_dive_state(_anchors[_anchor_index])


func _resolve_camera() -> Camera2D:
	var viewport_camera := get_viewport().get_camera_2d()
	if viewport_camera != null and viewport_camera.enabled:
		return viewport_camera

	if not camera_path.is_empty():
		var assigned_camera := get_node_or_null(camera_path) as Camera2D
		if assigned_camera != null:
			return assigned_camera

	var current_scene := get_tree().current_scene
	if current_scene != null:
		var player := current_scene.find_child("Player", true, false)
		if player != null:
			var player_camera := player.get_node_or_null("Camera2D") as Camera2D
			if player_camera != null:
				return player_camera

	return get_viewport().get_camera_2d()


func _build_anchor_path() -> void:
	var right_side: Array[PatrolAnchor] = [
		PatrolAnchor.MID_RIGHT,
		PatrolAnchor.TOP_RIGHT,
		PatrolAnchor.MID_RIGHT,
		PatrolAnchor.BOTTOM_RIGHT,
		PatrolAnchor.MID_RIGHT,
	]
	var left_side: Array[PatrolAnchor] = [
		PatrolAnchor.MID_LEFT,
		PatrolAnchor.TOP_LEFT,
		PatrolAnchor.MID_LEFT,
		PatrolAnchor.BOTTOM_LEFT,
		PatrolAnchor.MID_LEFT,
	]
	var ordered: Array[PatrolAnchor] = right_side + left_side

	if use_randomized_path:
		var path_segments: Array = [right_side, left_side]
		path_segments.shuffle()
		ordered = []
		for segment in path_segments:
			ordered.append_array(segment)

	_anchors = ordered
	_anchor_index = 0


func _go_to_next_anchor() -> void:
	_previous_anchor = _anchors[_anchor_index]
	_anchor_index += 1
	if _anchor_index < _anchors.size():
		return

	if use_randomized_path and reshuffle_each_loop:
		_build_anchor_path()
		return

	_anchor_index = 0
	_previous_anchor = _anchors[_anchors.size() - 1]


func _update_dive_state(target_anchor: PatrolAnchor) -> void:
	if _sprite == null:
		return

	_sprite.visible = not _is_dive_segment(_previous_anchor, target_anchor)


func _is_dive_segment(from_anchor: PatrolAnchor, to_anchor: PatrolAnchor) -> bool:
	return (_is_left_anchor(from_anchor) and _is_right_anchor(to_anchor)) or (_is_right_anchor(from_anchor) and _is_left_anchor(to_anchor))


func _is_left_anchor(anchor: PatrolAnchor) -> bool:
	return anchor == PatrolAnchor.MID_LEFT or anchor == PatrolAnchor.TOP_LEFT or anchor == PatrolAnchor.BOTTOM_LEFT


func _is_right_anchor(anchor: PatrolAnchor) -> bool:
	return anchor == PatrolAnchor.MID_RIGHT or anchor == PatrolAnchor.TOP_RIGHT or anchor == PatrolAnchor.BOTTOM_RIGHT


func _get_anchor_world_position(anchor: PatrolAnchor) -> Vector2:
	var visible_rect: Rect2 = get_viewport().get_visible_rect()
	var canvas_to_screen: Transform2D = get_viewport().get_canvas_transform()
	var screen_to_canvas: Transform2D = canvas_to_screen.affine_inverse()

	var top_left: Vector2 = screen_to_canvas * visible_rect.position
	var bottom_right: Vector2 = screen_to_canvas * visible_rect.end
	var left_x: float = top_left.x + border_padding.x
	var right_x: float = bottom_right.x - border_padding.x
	var top: float = top_left.y
	var bottom: float = bottom_right.y
	var center: Vector2 = (top_left + bottom_right) * 0.5

	match anchor:
		PatrolAnchor.MID_RIGHT:
			return Vector2(right_x, center.y - mid_anchor_lift)
		PatrolAnchor.TOP_RIGHT:
			return Vector2(right_x, top + border_padding.y - top_anchor_lift)
		PatrolAnchor.BOTTOM_RIGHT:
			return Vector2(right_x, bottom - border_padding.y + 10.0)
		PatrolAnchor.BOTTOM_LEFT:
			return Vector2(left_x, bottom - border_padding.y + 10.0)
		PatrolAnchor.TOP_LEFT:
			return Vector2(left_x, top + border_padding.y - top_anchor_lift)
		PatrolAnchor.MID_LEFT:
			return Vector2(left_x, center.y - mid_anchor_lift)

	return center
