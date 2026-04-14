extends Node12MageBase
class_name Node12MageEarth

const EARTH_PROJECTILE_SCENE := preload("res://game/chapter_4/node_12/npc/mage/mage_earth/earth_projectile.tscn")

enum projectile_attack_state {
	SUMMON_PROJECTILE,
	TELEGRAPH,
	SHOOT,
	VULNERABLE
}

@export var telegraph_duration: float = 1.0
@export var minimum_visual_telegraph_duration: float = 0.2

@export_group("Projectile Config")
@export var projectile_count: int = 10
@export var spread_degrees: float = 30.0
@export var summon_distance: float = 50.0
@export var summon_duration: float = 0.0

var _projectile_phase: projectile_attack_state = projectile_attack_state.SUMMON_PROJECTILE
var projectile_container: Node2D

func _ready() -> void:
	mage_element = "earth"
	required_reflect_element = "earth"
	projectile_speed = 2000.0
	super._ready()

	_ensure_projectile_container()
	projectile_container.global_position = global_position

func _exit_tree() -> void:
	if projectile_container != null and is_instance_valid(projectile_container):
		projectile_container.queue_free()
	super._exit_tree()

func perform_pattern_attack() -> void:
	modulate = Color(0.9, 0.85, 0.72, 1.0)
	await get_tree().create_timer(0.35).timeout
	modulate = Color(1, 1, 1, 1)

func perform_projectile_attack() -> void:
	_projectile_phase = projectile_attack_state.SUMMON_PROJECTILE

	var base_dir := get_direction_to_player()
	await _state_summon_projectiles(base_dir)

	_projectile_phase = projectile_attack_state.TELEGRAPH
	await _state_telegraph()

	_projectile_phase = projectile_attack_state.SHOOT
	_state_shoot()

	_projectile_phase = projectile_attack_state.VULNERABLE
	await _state_vulnerable_wait()

func _state_summon_projectiles(base_dir: Vector2) -> void:
	_ensure_projectile_container()
	_attach_projectile_container_if_needed()
	projectile_container.global_position = global_position
	projectile_container.global_rotation = base_dir.angle()
	var half_spread := deg_to_rad(spread_degrees) * 0.5

	for i in range(projectile_count):
		var t := 0.0
		if projectile_count > 1:
			t = float(i) / float(projectile_count - 1)
		var angle = lerp(-half_spread, half_spread, t)
		var shot_dir := base_dir.rotated(angle)
		_spawn_earth_projectile(shot_dir)

	if summon_duration > 0.0:
		await get_tree().create_timer(summon_duration).timeout

func _state_telegraph() -> void:
	_aim_projectile_container_at_player()
	_refresh_projectile_launch_directions()
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
		_aim_projectile_container_at_player()
		_refresh_projectile_launch_directions()
		remaining -= get_process_delta_time()


func _state_shoot() -> void:
	_refresh_projectile_launch_directions()
	for projectile in _get_container_projectiles():
		if projectile == null or not is_instance_valid(projectile):
			continue
		if projectile.has_method("shoot"):
			projectile.call("shoot")

func _state_vulnerable_wait() -> void:
	modulate = Color(1.0, 0.8, 0.8, 1.0)
	while has_active_projectiles() and _hp > 0:
		await get_tree().process_frame
	modulate = Color(1, 1, 1, 1)

func _spawn_earth_projectile(direction: Vector2) -> Area2D:
	_ensure_projectile_container()
	var projectile_instance := EARTH_PROJECTILE_SCENE.instantiate()
	if projectile_instance == null or not (projectile_instance is Area2D):
		return null

	var projectile := projectile_instance as Area2D
	projectile_container.add_child(projectile)
	projectile.position = direction.normalized() * summon_distance
	projectile.z_as_relative = false
	projectile.z_index = 20

	projectile.set("damage", attack_damage)
	projectile.set("source_element", mage_element)
	projectile.set("owner_mage", self)
	projectile.set("launch_direction", direction.normalized())
	projectile.set("base_speed", projectile_speed)

	register_projectile(projectile)
	return projectile

func _ensure_projectile_container() -> void:
	if projectile_container == null or not is_instance_valid(projectile_container):
		projectile_container = Node2D.new()
		projectile_container.name = "EarthProjectileContainer"
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

func _aim_projectile_container_at_player() -> void:
	if projectile_container == null or not is_instance_valid(projectile_container):
		return
	projectile_container.global_position = global_position
	if _player_ref == null or not is_instance_valid(_player_ref):
		return
	var to_player := _player_ref.global_position - projectile_container.global_position
	if to_player.length_squared() <= 0.0001:
		return
	projectile_container.global_rotation = to_player.angle()

func _refresh_projectile_launch_directions() -> void:
	if projectile_container == null or not is_instance_valid(projectile_container):
		return
	for projectile in _get_container_projectiles():
		var dir := (projectile.global_position - projectile_container.global_position).normalized()
		if dir.length_squared() <= 0.0001:
			continue
		if projectile.has_method("set_launch_direction"):
			projectile.call("set_launch_direction", dir)
		elif projectile.has_method("aim_at"):
			projectile.call("aim_at", projectile.global_position + dir)

func _get_container_projectiles() -> Array[Area2D]:
	var projectiles: Array[Area2D] = []
	for child in projectile_container.get_children():
		if child is Area2D and is_instance_valid(child):
			projectiles.append(child as Area2D)
	return projectiles
