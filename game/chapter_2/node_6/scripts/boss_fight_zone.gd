extends Area2D

signal boss_fight_started(player: Node2D)
signal boss_fight_won(player: Node2D)

@export var _zone_shape: CollisionShape2D = get_node_or_null("BossFightZone") as CollisionShape2D
@export var _trigger_area: Area2D = get_node_or_null("BossFightTrigger") as Area2D
@export var _borders: StaticBody2D = get_node_or_null("BossFightZoneBorders") as StaticBody2D
@export var _water_serpent: Node2D
@export var _debug_auto_win: bool = true
@export_range(0.5, 30.0, 0.5) var _debug_win_delay: float = 10.0

var _tracked_player: Node2D = null
var _tracked_camera: Camera2D = null
var _has_started: bool = false
var _has_won: bool = false

var _saved_limit_left: int = 0
var _saved_limit_right: int = 0
var _saved_limit_top: int = 0
var _saved_limit_bottom: int = 0


func _ready() -> void:
	_set_borders_enabled(false)
	if _trigger_area != null:
		_trigger_area.body_entered.connect(_on_trigger_body_entered)
		_trigger_area.area_entered.connect(_on_trigger_area_entered)
	_bind_water_serpent()


func _on_trigger_body_entered(body: Node) -> void:
	if _has_won:
		return

	var player := _get_player_from_body(body)
	if player == null:
		return
	_start_boss_fight(player)


func _on_trigger_area_entered(area: Area2D) -> void:
	if _has_won:
		return

	var player := _get_player_from_area(area)
	if player == null:
		return
	_start_boss_fight(player)


func _start_boss_fight(player: Node2D) -> void:
	if _has_started or _has_won:
		return

	var camera := _find_player_camera(player)
	if camera == null:
		return

	_has_started = true
	_tracked_player = player
	_tracked_camera = camera
	_set_borders_enabled(true)
	_save_camera_limits(camera)
	_apply_zone_limits(camera)
	_awaken_water_serpent()

	ObjectiveManager.set_objective("Defeat the Water Serpent!")
	boss_fight_started.emit(player)
	_start_debug_win_timer()


func _start_debug_win_timer() -> void:
	if not _debug_auto_win:
		return

	await get_tree().create_timer(_debug_win_delay).timeout
	if _has_started and not _has_won:
		print("Water Serpent defeated")
		_finish_boss_fight_win()


func _bind_water_serpent() -> void:
	if _water_serpent == null:
		_water_serpent = get_tree().current_scene.find_child("WaterSerpent", true, false) as Node2D

	if _water_serpent == null:
		return

	if _water_serpent.has_signal("boss_defeated") and not _water_serpent.is_connected("boss_defeated", Callable(self, "_on_water_serpent_defeated")):
		_water_serpent.connect("boss_defeated", Callable(self, "_on_water_serpent_defeated"))
	if _water_serpent.has_signal("defeated") and not _water_serpent.is_connected("defeated", Callable(self, "_on_water_serpent_defeated")):
		_water_serpent.connect("defeated", Callable(self, "_on_water_serpent_defeated"))
	if not _water_serpent.is_connected("tree_exited", Callable(self, "_on_water_serpent_tree_exited")):
		_water_serpent.tree_exited.connect(_on_water_serpent_tree_exited)


func _awaken_water_serpent() -> void:
	_bind_water_serpent()
	if _water_serpent == null:
		return

	if _water_serpent.has_method("awaken"):
		_water_serpent.call_deferred("awaken")


func _on_water_serpent_defeated() -> void:
	_finish_boss_fight_win()


func _on_water_serpent_tree_exited() -> void:
	if _has_started and not _has_won:
		_finish_boss_fight_win()


func _finish_boss_fight_win() -> void:
	if _has_won:
		return

	_has_won = true
	_has_started = false

	if _tracked_camera != null:
		_restore_camera_limits(_tracked_camera)

	_set_borders_enabled(false)
	_disable_trigger_area()

	ObjectiveManager.set_objective("Continue to town")
	boss_fight_won.emit(_tracked_player)

	_tracked_player = null
	_tracked_camera = null


func _disable_trigger_area() -> void:
	if _trigger_area == null:
		return

	_trigger_area.set_deferred("monitoring", false)
	_trigger_area.set_deferred("monitorable", false)


func _is_player(body: Node) -> bool:
	if body == null:
		return false

	return body.is_in_group("player") or body.name == "Player"


func _get_player_from_body(body: Node) -> Node2D:
	if _is_player(body) and body is Node2D:
		return body as Node2D
	return null


func _get_player_from_area(area: Area2D) -> Node2D:
	if area == null:
		return null

	if area.is_in_group("player_hurtbox"):
		var owner := area.get_parent()
		if _is_player(owner) and owner is Node2D:
			return owner as Node2D

	if _is_player(area) and area is Node2D:
		return area as Node2D

	return null


func _find_player_camera(player: Node2D) -> Camera2D:
	if player == null:
		return null

	var local_camera := player.get_node_or_null("Camera2D")
	if local_camera is Camera2D:
		return local_camera as Camera2D

	return get_tree().root.find_child("Camera2D", true, false) as Camera2D


func _save_camera_limits(camera: Camera2D) -> void:
	_saved_limit_left = camera.limit_left
	_saved_limit_right = camera.limit_right
	_saved_limit_top = camera.limit_top
	_saved_limit_bottom = camera.limit_bottom


func _apply_zone_limits(camera: Camera2D) -> void:
	if _zone_shape == null:
		return
	if not (_zone_shape.shape is RectangleShape2D):
		return

	var zone_rect_shape := _zone_shape.shape as RectangleShape2D
	var half_size := zone_rect_shape.size * 0.5
	var center := _zone_shape.global_position

	camera.limit_left = int(floor(center.x - half_size.x))
	camera.limit_right = int(ceil(center.x + half_size.x))
	camera.limit_top = int(floor(center.y - half_size.y))
	camera.limit_bottom = int(ceil(center.y + half_size.y))


func _restore_camera_limits(camera: Camera2D) -> void:
	camera.limit_left = _saved_limit_left
	camera.limit_right = _saved_limit_right
	camera.limit_top = _saved_limit_top
	camera.limit_bottom = _saved_limit_bottom


func _set_borders_enabled(enabled: bool) -> void:
	if _borders == null:
		return

	for child in _borders.get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", not enabled)
