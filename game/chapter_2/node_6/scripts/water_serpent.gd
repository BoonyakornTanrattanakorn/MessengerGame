extends Node2D

signal intro_rise_finished
signal dive_to_right_finished
signal defeat_sequence_finished
signal defeat_rise_finished
signal defeat_final_dive_finished
signal attack_set_completed(total_sets: int)

enum PatrolAnchor {
	MID_RIGHT,
	TOP_RIGHT,
	BOTTOM_RIGHT,
	BOTTOM_LEFT,
	TOP_LEFT,
	MID_LEFT,
}

enum DiveState {
	NONE,
	SINKING,
	RISING,
}

@export var camera_path: NodePath = NodePath("../../Player/Camera2D")
@export var swim_speed: float = 140.0
@export var arrival_distance: float = 2.0
@export var border_padding: Vector2 = Vector2(88.0, 72.0)
@export var mid_anchor_lift: float = 22.0
@export var top_anchor_lift: float = 30.0
@export var dive_animation_name: StringName = &"dive"
@export var rise_animation_name: StringName = &"rise"
@export var idle_animation_name: StringName = &"idle"
@export var water_ball_scene: PackedScene = preload("res://game/chapter_2/node_6/scenes/water_ball.tscn")
@export var right_side_flip_h: bool = true
@export var left_side_flip_h: bool = false
@export var start_awake: bool = false
@export var use_randomized_path: bool = false
@export var reshuffle_each_loop: bool = true

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _camera: Camera2D
var _initial_global_position: Vector2 = Vector2.ZERO
var _anchors: Array[PatrolAnchor] = []
var _anchor_index: int = 0
var _previous_anchor: PatrolAnchor = PatrolAnchor.MID_RIGHT
var _last_camera_center: Vector2 = Vector2.ZERO
var _has_last_camera_center: bool = false
var _dive_state: DiveState = DiveState.NONE
var _dive_target_anchor: PatrolAnchor = PatrolAnchor.MID_RIGHT
var _active_dive_animation: StringName = StringName()
var _active_rise_animation: StringName = StringName()
var _is_awake: bool = false
var _is_awakening_intro: bool = false
var _is_forced_dive_to_right: bool = false
var _is_playing_defeat_sequence: bool = false
var _set_has_left_to_right: bool = false
var _set_has_right_to_left: bool = false
var _completed_attack_sets: int = 0


func _ready() -> void:
	_camera = _resolve_camera()
	_initial_global_position = global_position
	_build_anchor_path()
	if _camera == null:
		push_warning("WaterSerpent: Camera2D not found. The serpent will keep trying to bind in _process.")
		return

	if _sprite != null and not _sprite.animation_finished.is_connected(_on_sprite_animation_finished):
		_sprite.animation_finished.connect(_on_sprite_animation_finished)

	_is_awake = start_awake
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

	if not _is_awake:
		return

	if _is_playing_defeat_sequence:
		return

	var camera_center: Vector2 = _camera.get_screen_center_position()
	if _has_last_camera_center:
		# Keep serpent anchored to the camera space while still swimming between anchors.
		global_position += camera_center - _last_camera_center
	_last_camera_center = camera_center
	_has_last_camera_center = true

	if _dive_state != DiveState.NONE or _is_awakening_intro:
		return

	var target_anchor: PatrolAnchor = _anchors[_anchor_index]
	var target_position: Vector2 = _get_anchor_world_position(target_anchor)
	global_position = global_position.move_toward(target_position, swim_speed * delta)

	if global_position.distance_to(target_position) <= arrival_distance:
		if _should_shoot_at_anchor(target_anchor):
			_shoot_water_ball(target_anchor)
		_go_to_next_anchor()
		_update_dive_state(_anchors[_anchor_index])


func awaken() -> void:
	if _is_awake or _is_awakening_intro:
		return

	_is_awake = true
	if _camera != null:
		_last_camera_center = _camera.get_screen_center_position()
		_has_last_camera_center = true
	_update_dive_state(_anchors[_anchor_index])


func prepare_intro_underwater() -> void:
	if _sprite == null:
		return

	_is_awake = false
	_is_awakening_intro = false
	_dive_state = DiveState.NONE
	_update_sprite_facing(_anchors[_anchor_index])

	_active_dive_animation = _resolve_dive_animation_name()
	if _active_dive_animation.is_empty():
		# Fallback when no dive animation exists.
		_sprite.visible = false
		return

	_sprite.visible = true
	_sprite.play(_active_dive_animation)
	var frame_count: int = _sprite.sprite_frames.get_frame_count(_active_dive_animation)
	if frame_count > 0:
		_sprite.frame = frame_count - 1
	_sprite.pause()


func play_intro_rise() -> void:
	if _is_awakening_intro:
		return

	_active_rise_animation = _resolve_rise_animation_name()
	if _sprite == null or _active_rise_animation.is_empty():
		# Fallback for older content that only has dive.
		_active_dive_animation = _resolve_dive_animation_name()
		if _active_dive_animation.is_empty():
			intro_rise_finished.emit()
			return
		_active_rise_animation = _active_dive_animation

	if _sprite == null:
		intro_rise_finished.emit()
		return

	_is_awake = false
	_dive_state = DiveState.NONE
	_sprite.visible = true

	_update_sprite_facing(_anchors[_anchor_index])
	_is_awakening_intro = true
	_sprite.play(_active_rise_animation)


func play_dive_to_right_and_awaken() -> void:
	if _sprite == null:
		_is_awake = true
		dive_to_right_finished.emit()
		return

	if _dive_state != DiveState.NONE or _is_awakening_intro:
		return

	_is_awake = false
	_is_forced_dive_to_right = true
	_start_dive_transition(PatrolAnchor.MID_RIGHT)


func reset_attack_sets() -> void:
	_set_has_left_to_right = false
	_set_has_right_to_left = false
	_completed_attack_sets = 0


func reset_encounter_state() -> void:
	_build_anchor_path()
	_anchor_index = 0
	_previous_anchor = PatrolAnchor.MID_RIGHT
	_dive_target_anchor = PatrolAnchor.MID_RIGHT
	_dive_state = DiveState.NONE
	_active_dive_animation = StringName()
	_active_rise_animation = StringName()
	_is_awake = start_awake
	_is_awakening_intro = false
	_is_forced_dive_to_right = false
	_is_playing_defeat_sequence = false
	reset_attack_sets()
	global_position = _initial_global_position

	if _camera == null:
		_camera = _resolve_camera()

	if _camera != null:
		_last_camera_center = _camera.get_screen_center_position()
		_has_last_camera_center = true

	if _sprite != null:
		_sprite.visible = true
		_update_dive_state(_anchors[_anchor_index])


func play_defeat_rise_at_right() -> void:
	if _is_playing_defeat_sequence:
		return

	_is_playing_defeat_sequence = true
	_is_awake = false
	_is_awakening_intro = false
	_dive_state = DiveState.NONE

	if _sprite == null:
		defeat_sequence_finished.emit()
		return

	_sprite.visible = true

	var dive_anim := _resolve_dive_animation_name()
	var rise_anim := _resolve_rise_animation_name()

	# Dive from current position.
	if not dive_anim.is_empty():
		_sprite.play(dive_anim)
		await _sprite.animation_finished

	# Re-emerge at mid-right.
	global_position = _get_anchor_world_position(PatrolAnchor.MID_RIGHT)
	_update_sprite_facing(PatrolAnchor.MID_RIGHT)
	_anchor_index = 0
	_previous_anchor = PatrolAnchor.MID_RIGHT

	if not rise_anim.is_empty():
		_sprite.play(rise_anim)
		await _sprite.animation_finished

	defeat_rise_finished.emit()


func play_defeat_final_dive() -> void:
	if _sprite == null:
		_is_playing_defeat_sequence = false
		defeat_final_dive_finished.emit()
		defeat_sequence_finished.emit()
		return

	var dive_anim := _resolve_dive_animation_name()
	if not dive_anim.is_empty():
		_sprite.play(dive_anim)
		await _sprite.animation_finished

	_sprite.visible = false
	_is_playing_defeat_sequence = false
	defeat_final_dive_finished.emit()
	defeat_sequence_finished.emit()


func play_defeat_sequence() -> void:
	await play_defeat_rise_at_right()
	await play_defeat_final_dive()


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
	if _is_dive_segment(_previous_anchor, target_anchor):
		_register_cross_side_transition(_previous_anchor, target_anchor)
		_start_dive_transition(target_anchor)
		return

	_update_sprite_facing(target_anchor)
	_play_surface_animation()


func _update_sprite_facing(target_anchor: PatrolAnchor) -> void:
	if _sprite == null:
		return

	if _is_right_anchor(target_anchor):
		_sprite.flip_h = right_side_flip_h
	elif _is_left_anchor(target_anchor):
		_sprite.flip_h = left_side_flip_h


func _start_dive_transition(target_anchor: PatrolAnchor) -> void:
	# Sink animation should face based on the side we are currently on.
	_update_sprite_facing(_previous_anchor)

	_active_dive_animation = _resolve_dive_animation_name()
	if _sprite == null or _active_dive_animation.is_empty():
		global_position = _get_anchor_world_position(target_anchor)
		_dive_state = DiveState.NONE
		_update_sprite_facing(target_anchor)
		if _is_forced_dive_to_right:
			_is_forced_dive_to_right = false
			_is_awake = true
			dive_to_right_finished.emit()
			return
		_play_surface_animation()
		return

	_dive_target_anchor = target_anchor
	_dive_state = DiveState.SINKING
	_sprite.play(_active_dive_animation)


func _on_sprite_animation_finished() -> void:
	if _sprite == null:
		return

	if _is_awakening_intro and _sprite.animation == _active_rise_animation:
		_is_awakening_intro = false
		_active_rise_animation = StringName()
		_active_dive_animation = StringName()
		intro_rise_finished.emit()
		return

	if _dive_state == DiveState.SINKING and _sprite.animation == _active_dive_animation:
		global_position = _get_anchor_world_position(_dive_target_anchor)
		# After teleport, face based on destination side for the reverse animation.
		_update_sprite_facing(_dive_target_anchor)
		_dive_state = DiveState.RISING
		_sprite.play(_active_dive_animation, -1.0, true)
		return

	if _dive_state == DiveState.RISING and _sprite.animation == _active_dive_animation:
		_dive_state = DiveState.NONE
		_active_dive_animation = StringName()
		if _is_forced_dive_to_right:
			_is_forced_dive_to_right = false
			_is_awake = true
			_anchor_index = 0
			_previous_anchor = PatrolAnchor.MID_RIGHT
			if _camera != null:
				_last_camera_center = _camera.get_screen_center_position()
				_has_last_camera_center = true
			dive_to_right_finished.emit()
			_update_dive_state(_anchors[_anchor_index])
			return
		_play_surface_animation()


func _play_surface_animation() -> void:
	if _sprite == null:
		return

	if _has_animation(idle_animation_name):
		if _sprite.animation != idle_animation_name or not _sprite.is_playing():
			_sprite.play(idle_animation_name)


func _has_animation(animation_name: StringName) -> bool:
	if _sprite == null or _sprite.sprite_frames == null:
		return false

	return _sprite.sprite_frames.has_animation(animation_name)


func _resolve_dive_animation_name() -> StringName:
	if _has_animation(dive_animation_name):
		return dive_animation_name

	# Allow common naming variants to avoid accidental instant teleports.
	for fallback in [&"dive", &"diving", &"Dive", &"Diving"]:
		if _has_animation(fallback):
			return fallback

	return StringName()


func _resolve_rise_animation_name() -> StringName:
	if _has_animation(rise_animation_name):
		return rise_animation_name

	for fallback in [&"rise", &"Rise"]:
		if _has_animation(fallback):
			return fallback

	return StringName()


func _should_shoot_at_anchor(anchor: PatrolAnchor) -> bool:
	return anchor == PatrolAnchor.TOP_RIGHT or anchor == PatrolAnchor.TOP_LEFT or anchor == PatrolAnchor.BOTTOM_RIGHT or anchor == PatrolAnchor.BOTTOM_LEFT


func _shoot_water_ball(anchor: PatrolAnchor) -> void:
	if water_ball_scene == null:
		return

	var water_ball := water_ball_scene.instantiate()
	if water_ball == null:
		return

	var direction: Vector2 = _get_water_ball_direction(anchor)
	if water_ball.has_method("initialize"):
		water_ball.initialize(global_position, direction)
	else:
		water_ball.global_position = global_position

	get_tree().current_scene.add_child(water_ball)


func _get_water_ball_direction(anchor: PatrolAnchor) -> Vector2:
	var player := _find_player()
	if player != null:
		var to_player: Vector2 = player.global_position - global_position
		if to_player.length() > 0.001:
			return to_player.normalized()

	if _is_right_anchor(anchor):
		return Vector2.LEFT
	return Vector2.RIGHT


func _find_player() -> Node2D:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return null

	var player := current_scene.find_child("Player", true, false)
	if player is Node2D:
		return player as Node2D

	return null


func _is_dive_segment(from_anchor: PatrolAnchor, to_anchor: PatrolAnchor) -> bool:
	return (_is_left_anchor(from_anchor) and _is_right_anchor(to_anchor)) or (_is_right_anchor(from_anchor) and _is_left_anchor(to_anchor))


func _register_cross_side_transition(from_anchor: PatrolAnchor, to_anchor: PatrolAnchor) -> void:
	if _is_forced_dive_to_right or _is_playing_defeat_sequence or _is_awakening_intro:
		return

	if _is_left_anchor(from_anchor) and _is_right_anchor(to_anchor):
		_set_has_left_to_right = true
	elif _is_right_anchor(from_anchor) and _is_left_anchor(to_anchor):
		_set_has_right_to_left = true

	if _set_has_left_to_right and _set_has_right_to_left:
		_completed_attack_sets += 1
		attack_set_completed.emit(_completed_attack_sets)
		_set_has_left_to_right = false
		_set_has_right_to_left = false


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
