extends SubViewport

@export var target_node_name: String = "Player"
@export_range(0.05, 2.0, 0.01) var minimap_zoom_scale: float = 0.3
@export_range(0.5, 4.0, 0.1) var minimap_display_scale: float = 1.0
@export var minimap_viewport_size: Vector2i = Vector2i(215, 188)

var _target: Node2D
var _minimap_camera: Camera2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	world_2d = get_tree().root.world_2d

	_minimap_camera = Camera2D.new()
	_minimap_camera.enabled = true
	add_child(_minimap_camera)

	_apply_config()

	_target = get_tree().current_scene.get_node_or_null(target_node_name) as Node2D


func _apply_config() -> void:
	# Godot locks SubViewport size when parent SubViewportContainer uses stretch.
	# Skip manual size updates in that case to avoid runtime warnings.
	var container := get_parent()
	var can_set_size := true
	if container is SubViewportContainer and (container as SubViewportContainer).stretch:
		can_set_size = false

	if can_set_size and size != minimap_viewport_size:
		size = minimap_viewport_size
	if _minimap_camera != null:
		_minimap_camera.zoom = Vector2(minimap_zoom_scale, minimap_zoom_scale)

	if container is Control:
		(container as Control).scale = Vector2(minimap_display_scale, minimap_display_scale)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_apply_config()

	if _target == null:
		_target = get_tree().current_scene.get_node_or_null(target_node_name) as Node2D
		return

	_minimap_camera.global_position = _target.global_position
