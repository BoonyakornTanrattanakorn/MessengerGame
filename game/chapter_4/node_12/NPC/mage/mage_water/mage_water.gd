extends Node12MageBase
class_name Node12MageWater

const WATER_PROJECTILE_SCENE := preload("res://game/chapter_4/node_12/npc/mage/mage_water/water_projectile.tscn")

@export var telegraph_duration: float = 0.5
@export var projectile_count: int = 3
@export var spawn_ring_radius: float = 200.0
@export var shot_delay: float = 1.2
@export var pre_shot_warning_duration: float = 0.1

func _ready() -> void:
	mage_element = "water"
	required_reflect_element = "water"
	projectile_speed = 1000.0
	max_hp = 5.0
	randomize()
	super._ready()

func perform_pattern_attack() -> void:
	_play_mage_sfx("mage.cast.water")
	modulate = Color(0.72, 0.9, 1.0, 1.0)
	await get_tree().create_timer(0.3).timeout
	modulate = Color(1, 1, 1, 1)

func perform_projectile_attack() -> void:
	_play_mage_sfx("mage.cast.water")
	modulate = Color(0.88, 0.96, 1.0, 1.0)
	var count = max(1, projectile_count)
	for i in range(count):
		if _hp <= 0:
			break
		await _wait_for_projectiles_to_end()

		var projectile := _spawn_one_water_projectile()
		if projectile == null or not is_instance_valid(projectile):
			continue

		await _telegraph_projectiles([projectile])
		await _shoot_projectiles([projectile])
		await _wait_for_projectiles_to_end()

		if shot_delay > 0.0 and i < count - 1:
			if get_tree() == null:
				break
			var tree := get_tree()
			await tree.create_timer(shot_delay).timeout

	modulate = Color(1, 1, 1, 1)

func _spawn_one_water_projectile() -> Area2D:
	var player_center := _player_ref.global_position if _player_ref != null and is_instance_valid(_player_ref) else global_position
	var base_angle := randf() * TAU
	var ring_dir := Vector2.RIGHT.rotated(base_angle)
	var spawn_pos := player_center + ring_dir * spawn_ring_radius
	var dir := (player_center - spawn_pos).normalized()
	return _spawn_water_projectile(spawn_pos, dir)

func _spawn_water_projectiles(base_dir: Vector2) -> Array[Area2D]:
	var spawned: Array[Area2D] = []
	var count = max(1, projectile_count)
	var player_center := _player_ref.global_position if _player_ref != null and is_instance_valid(_player_ref) else global_position

	for i in range(count):
		var base_angle := TAU * (float(i) / float(count))
		var jitter := randf_range(-0.25, 0.25)
		var ring_dir := Vector2.RIGHT.rotated(base_angle + jitter)
		var spawn_pos := player_center + ring_dir * spawn_ring_radius
		var dir := (player_center - spawn_pos).normalized()
		var projectile := _spawn_water_projectile(spawn_pos, dir)
		if projectile != null:
			spawned.append(projectile)

	return spawned

func _telegraph_projectiles(spawned: Array[Area2D]) -> void:
	for projectile in spawned:
		if projectile == null or not is_instance_valid(projectile):
			continue
		if projectile.has_method("set_telegraph"):
			projectile.call("set_telegraph", true)

	if telegraph_duration <= 0.0:
		return

	var remaining := telegraph_duration
	while remaining > 0.0:
		await get_tree().process_frame
		remaining -= get_process_delta_time()

func _shoot_projectiles(spawned: Array[Area2D]) -> void:
	for i in range(spawned.size()):
		var projectile := spawned[i]
		if projectile == null or not is_instance_valid(projectile):
			continue
		if projectile.has_method("play_pre_shoot_warning"):
			await projectile.call("play_pre_shoot_warning", pre_shot_warning_duration)

		if projectile.has_method("shoot"):
			projectile.call("shoot")
		if shot_delay > 0.0 and i < spawned.size() - 1:
			await get_tree().create_timer(shot_delay).timeout

func _wait_for_projectiles_to_end() -> void:
	while has_active_projectiles() and _hp > 0:
		if get_tree() == null:
			break
		var tree := get_tree()
		await tree.process_frame

func _spawn_water_projectile(spawn_pos: Vector2, direction: Vector2) -> Area2D:
	var projectile_instance := WATER_PROJECTILE_SCENE.instantiate()
	if projectile_instance == null or not (projectile_instance is Area2D):
		return null

	var projectile := projectile_instance as Area2D
	projectile.top_level = true
	projectile.global_position = spawn_pos

	projectile.set("damage", 1.0)
	projectile.set("source_element", mage_element)
	projectile.set("owner_mage", self)
	projectile.set("launch_direction", direction.normalized())
	projectile.set("base_speed", projectile_speed)

	var scene_root := get_tree().current_scene
	if scene_root != null:
		scene_root.add_child(projectile)

	register_projectile(projectile)
	return projectile
