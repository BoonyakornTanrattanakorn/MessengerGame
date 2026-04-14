extends Node12MageBase
class_name Node12MageFire

const FIRE_PROJECTILE_SCENE := preload("res://game/chapter_4/node_12/npc/mage/mage_fire/fire_projectile.tscn")

@export var telegraph_duration: float = 0.6
@export var projectile_count: int = 3
@export var summon_radius: float = 26.0
@export var shot_interval: float = 0.08

func _ready() -> void:
	mage_element = "fire"
	required_reflect_element = "fire"
	projectile_speed = 200.0
	max_hp = 5.0
	super._ready()

func perform_pattern_attack() -> void:
	modulate = Color(1.0, 0.72, 0.62, 1.0)
	await get_tree().create_timer(0.28).timeout
	modulate = Color(1, 1, 1, 1)

func perform_projectile_attack() -> void:
	modulate = Color(1.0, 0.85, 0.85, 1.0)
	var count = max(1, projectile_count)
	for i in range(count):
		if _hp <= 0:
			break
		var base_dir := get_direction_to_player()
		var spawn_pos := global_position + base_dir * summon_radius
		var projectile := _spawn_fire_projectile(spawn_pos, base_dir)
		if projectile == null:
			continue

		await _telegraph_single_fireball(projectile)
		if projectile != null and is_instance_valid(projectile) and projectile.has_method("shoot"):
			projectile.call("shoot")

		await _wait_for_projectile_to_despawn(projectile)
		if shot_interval > 0.0 and i < count - 1:
			await get_tree().create_timer(shot_interval).timeout

	modulate = Color(1, 1, 1, 1)

func _telegraph_single_fireball(projectile: Area2D) -> void:
	if projectile == null or not is_instance_valid(projectile):
		return
	if projectile.has_method("set_telegraph"):
		projectile.call("set_telegraph", true)

	if telegraph_duration <= 0.0:
		return

	var remaining := telegraph_duration
	while remaining > 0.0:
		if projectile == null or not is_instance_valid(projectile):
			return
		await get_tree().process_frame
		if projectile.has_method("aim_at") and _player_ref != null and is_instance_valid(_player_ref):
			projectile.call("aim_at", _player_ref.global_position)
		remaining -= get_process_delta_time()

func _wait_for_projectile_to_despawn(projectile: Area2D) -> void:
	while projectile != null and is_instance_valid(projectile):
		if _hp <= 0:
			return
		await get_tree().process_frame

func _spawn_fireballs(base_dir: Vector2) -> Array[Area2D]:
	var spawned: Array[Area2D] = []
	var count = max(1, projectile_count)
	var half_spread := deg_to_rad(22.0)

	for i in range(count):
		var t := 0.5
		if count > 1:
			t = float(i) / float(count - 1)
		var angle = lerp(-half_spread, half_spread, t)
		var dir = base_dir.rotated(angle)
		var spawn_pos = global_position + dir * summon_radius
		var projectile = _spawn_fire_projectile(spawn_pos, dir)
		if projectile != null:
			spawned.append(projectile)

	return spawned

func _telegraph_fireballs(spawned: Array[Area2D]) -> void:
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
		for projectile in spawned:
			if projectile == null or not is_instance_valid(projectile):
				continue
			if projectile.has_method("aim_at") and _player_ref != null and is_instance_valid(_player_ref):
				projectile.call("aim_at", _player_ref.global_position)
		remaining -= get_process_delta_time()

func _shoot_fireballs(spawned: Array[Area2D]) -> void:
	for i in range(spawned.size()):
		var projectile := spawned[i]
		if projectile != null and is_instance_valid(projectile) and projectile.has_method("shoot"):
			projectile.call("shoot")
		if shot_interval > 0.0 and i < spawned.size() - 1:
			await get_tree().create_timer(shot_interval).timeout

func _wait_for_fireballs_to_end() -> void:
	modulate = Color(1.0, 0.85, 0.85, 1.0)
	while has_active_projectiles() and _hp > 0:
		await get_tree().process_frame
	modulate = Color(1, 1, 1, 1)

func _spawn_fire_projectile(spawn_pos: Vector2, direction: Vector2) -> Area2D:
	var projectile_instance := FIRE_PROJECTILE_SCENE.instantiate()
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
