extends Area2D

@onready var _zone_shape: CollisionShape2D = get_node_or_null("BossFightZone") as CollisionShape2D

var _tracked_player: Node2D = null
var _tracked_camera: Camera2D = null

var _saved_limit_left: int = 0
var _saved_limit_right: int = 0
var _saved_limit_top: int = 0
var _saved_limit_bottom: int = 0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if not _is_player(body):
		return

	var player := body as Node2D
	var camera := _find_player_camera(player)
	if camera == null:
		return

	_tracked_player = player
	_tracked_camera = camera
	_save_camera_limits(camera)
	_apply_zone_limits(camera)


func _on_body_exited(body: Node) -> void:
	if body != _tracked_player:
		return

	if _tracked_camera != null:
		_restore_camera_limits(_tracked_camera)

	_tracked_player = null
	_tracked_camera = null


func _is_player(body: Node) -> bool:
	if body == null:
		return false

	return body.is_in_group("player") or body.name == "Player"


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
