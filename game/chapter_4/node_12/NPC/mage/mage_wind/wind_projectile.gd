extends Node12MageBaseProjectile

var _detached_after_shot: bool = false

func _ready() -> void:
	if source_element == "":
		source_element = "wind"
	base_speed = 150.0
	damage = 0.2
	super._ready()

func _get_telegraph_tint() -> Color:
	return Color(0.72, 0.93, 1.0, 0.78)

func _get_reflected_tint() -> Color:
	return Color(0.58, 0.8, 1.0, 1.0)

func shoot() -> void:
	_detach_from_orbit_container()
	super.shoot()

func _detach_from_orbit_container() -> void:
	if _detached_after_shot:
		return
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	if get_parent() == scene_root:
		_detached_after_shot = true
		return

	reparent(scene_root, true)
	_detached_after_shot = true
