extends Node12MageBase
class_name Node12MageWind

const WIND_PROJECTILE_SCENE := preload("res://game/chapter_4/node_12/npc/mage/mage_wind/wind_projectile.tscn")

enum projectile_attack_state {
	SUMMON_PROJECTILE,
	TELEGRAPH,
	SHOOT,
	VULNERABLE
}

@export var telegraph_duration: float = 1.0
@export var minimum_visual_telegraph_duration: float = 0.3

@export_group("Projectile Config")
@export var projectile_count: int = 10
@export var orbit_radius: float = 150.0
@export var orbit_turn_speed_deg: float = 60.0
@export var summon_duration: float = 0.0
@export var shot_delay: float = 0.2

var _projectile_phase: projectile_attack_state = projectile_attack_state.SUMMON_PROJECTILE
var _orbit_rotation: float = 0.0
var projectile_container: Node2D

func _ready() -> void:
	mage_element = "wind"
	required_reflect_element = "wind"
	projectile_speed = 200.0
	randomize()
	super._ready()

	_ensure_projectile_container()
	projectile_container.global_position = global_position

func _exit_tree() -> void:
	if projectile_container != null and is_instance_valid(projectile_container):
		projectile_container.queue_free()
	super._exit_tree()

func perform_pattern_attack() -> void:
	modulate = Color(0.78, 0.92, 1.0, 1.0)
	await get_tree().create_timer(0.3).timeout
	modulate = Color(1, 1, 1, 1)

func perform_projectile_attack() -> void:
	_projectile_phase = projectile_attack_state.SUMMON_PROJECTILE

	var base_dir := get_direction_to_player()
	await _state_summon_projectiles(base_dir)

	_projectile_phase = projectile_attack_state.TELEGRAPH
	await _state_telegraph()

	_projectile_phase = projectile_attack_state.SHOOT
	await _state_shoot()

	_projectile_phase = projectile_attack_state.VULNERABLE
	await _state_vulnerable_wait()

func _state_summon_projectiles(base_dir: Vector2) -> void:
	_ensure_projectile_container()
	_attach_projectile_container_if_needed()
	var center := _get_orbit_center()
	projectile_container.global_position = center
	_orbit_rotation = base_dir.angle()
	projectile_container.global_rotation = _orbit_rotation

	for i in range(max(1, projectile_count)):
		var angle_step := TAU * (float(i) / float(max(1, projectile_count)))
		var dir := Vector2.RIGHT.rotated(angle_step)
		_spawn_wind_projectile(dir)

	if summon_duration > 0.0:
		await get_tree().create_timer(summon_duration).timeout

func _state_telegraph() -> void:
	for projectile in _get_container_projectiles():
		if projectile == null or not is_instance_valid(projectile):
			continue
		if projectile.has_method("set_telegraph"):
			projectile.call("set_telegraph", true)

	var visual_duration := telegraph_duration
	if visual_duration <= 0.0:
		visual_duration = minimum_visual_telegraph_duration
	if visual_duration <= 0.0:
		return

	var remaining := visual_duration
	while remaining > 0.0:
		await get_tree().process_frame
		var delta := get_process_delta_time()
		var center := _advance_orbit(delta)
		_refresh_projectile_launch_directions(center)
		remaining -= delta

func _state_shoot() -> void:
	var randomized := _get_container_projectiles()
	randomized.shuffle()
	for i in range(randomized.size()):
		var projectile := randomized[i]
		if projectile == null or not is_instance_valid(projectile):
			continue
		var center := _get_orbit_center()
		_update_projectile_launch_direction(projectile, center)
		if projectile.has_method("shoot"):
			projectile.call("shoot")
		if shot_delay > 0.0 and i < randomized.size() - 1:
			var remaining_delay := shot_delay
			while remaining_delay > 0.0:
				await get_tree().process_frame
				var delta := get_process_delta_time()
				var orbit_center := _advance_orbit(delta)
				for j in range(i + 1, randomized.size()):
					var pending := randomized[j]
					if pending == null or not is_instance_valid(pending):
						continue
					_update_projectile_launch_direction(pending, orbit_center)
				remaining_delay -= delta

func _state_vulnerable_wait() -> void:
	modulate = Color(1.0, 0.8, 0.8, 1.0)
	while has_active_projectiles() and _hp > 0:
		await get_tree().process_frame
	modulate = Color(1, 1, 1, 1)

func _spawn_wind_projectile(local_direction: Vector2) -> Area2D:
	_ensure_projectile_container()
	var projectile_instance := WIND_PROJECTILE_SCENE.instantiate()
	if projectile_instance == null or not (projectile_instance is Area2D):
		return null

	var projectile := projectile_instance as Area2D
	projectile_container.add_child(projectile)
	projectile.position = local_direction.normalized() * orbit_radius
	projectile.z_as_relative = false
	projectile.z_index = 20

	projectile.set("source_element", mage_element)
	projectile.set("owner_mage", self)
	projectile.set("launch_direction", (projectile.global_position - _get_orbit_center()).normalized())
	projectile.set("base_speed", projectile_speed)

	register_projectile(projectile)
	return projectile

func _ensure_projectile_container() -> void:
	if projectile_container == null or not is_instance_valid(projectile_container):
		projectile_container = Node2D.new()
		projectile_container.name = "WindProjectileContainer"
		projectile_container.z_as_relative = false
		projectile_container.z_index = 20

	if projectile_container.get_parent() == null:
		var scene_root := get_tree().current_scene
		if scene_root != null:
			scene_root.add_child.call_deferred(projectile_container)

func _attach_projectile_container_if_needed() -> void:
	if projectile_container == null or not is_instance_valid(projectile_container):
		return
	if projectile_container.get_parent() != null:
		return
	var scene_root := get_tree().current_scene
	if scene_root != null:
		scene_root.add_child(projectile_container)

func _get_orbit_center() -> Vector2:
	if _player_ref != null and is_instance_valid(_player_ref):
		return _player_ref.global_position
	return global_position

func _refresh_projectile_launch_directions(center: Vector2) -> void:
	for projectile in _get_container_projectiles():
		_update_projectile_launch_direction(projectile, center)

func _advance_orbit(delta: float) -> Vector2:
	var center := _get_orbit_center()
	_orbit_rotation += deg_to_rad(orbit_turn_speed_deg) * delta
	projectile_container.global_position = center
	projectile_container.global_rotation = _orbit_rotation
	return center

func _update_projectile_launch_direction(projectile: Area2D, center: Vector2) -> void:
	if projectile == null or not is_instance_valid(projectile):
		return
	var inward_dir := center - projectile.global_position
	if inward_dir.length_squared() <= 0.0001:
		return
	if projectile.has_method("set_launch_direction"):
		projectile.call("set_launch_direction", inward_dir.normalized())
	elif projectile.has_method("aim_at"):
		projectile.call("aim_at", center)

func _get_container_projectiles() -> Array[Area2D]:
	var projectiles: Array[Area2D] = []
	if projectile_container == null or not is_instance_valid(projectile_container):
		return projectiles
	for child in projectile_container.get_children():
		if child is Area2D and is_instance_valid(child):
			projectiles.append(child as Area2D)
	return projectiles
