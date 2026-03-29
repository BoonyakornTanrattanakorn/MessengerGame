extends SubViewport

@export var target_node_name: String = "Player"
@export var minimap_zoom: Vector2 = Vector2(0.12, 0.12)

var _target: Node2D
var _minimap_camera: Camera2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	world_2d = get_tree().root.world_2d

	_minimap_camera = Camera2D.new()
	_minimap_camera.enabled = true
	_minimap_camera.zoom = minimap_zoom
	add_child(_minimap_camera)

	_target = get_tree().current_scene.get_node_or_null(target_node_name) as Node2D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _target == null:
		_target = get_tree().current_scene.get_node_or_null(target_node_name) as Node2D
		return

	_minimap_camera.global_position = _target.global_position
