extends Node12MageBase
class_name Node12MageEarth

const EARTH_PROJECTILE_SCENE := preload("res://game/chapter_4/node_12/npc/mage/mage_earth/earth_projectile.tscn")

enum projectile_attack_state {
	SUMMON_PROJECTILE,
	TELEGRAPH,
	SHOOT,
	VULNERABLE
}

@export var telegraph_duration: float = 0.0

@export_group("Projectile Config")
@export var projectile_count: int = 10
@export var spread_degrees: float = 30.0
@export var summon_distance: float = 50.0
@export var summon_duration: float = 1.0

var _projectile_phase: projectile_attack_state = projectile_attack_state.SUMMON_PROJECTILE

func _ready() -> void:
	mage_element = "earth"
	required_reflect_element = "earth"
	projectile_speed = 2000.0
	super._ready()

func perform_attack_pattern() -> void:
	_projectile_phase = projectile_attack_state.SUMMON_PROJECTILE

	var base_dir := get_direction_to_player()
	var spawned := await _state_summon_projectiles(base_dir)

	_projectile_phase = projectile_attack_state.TELEGRAPH
	await _state_telegraph(spawned)

	_projectile_phase = projectile_attack_state.SHOOT
	_state_shoot(spawned)

	_projectile_phase = projectile_attack_state.VULNERABLE
	await _state_vulnerable_wait()

	finish_casting(attack_interval)

func _state_summon_projectiles(base_dir: Vector2) -> Array[Area2D]:
	var spawned: Array[Area2D] = []
	var count = max(3, projectile_count)
	var half_spread := deg_to_rad(spread_degrees) * 0.5

	for i in range(count):
		var t := 0.0
		if count > 1:
			t = float(i) / float(count - 1)
		var angle = lerp(-half_spread, half_spread, t)
		var shot_dir := base_dir.rotated(angle)
		var spawn_pos := global_position + shot_dir * summon_distance
		var projectile := _spawn_earth_projectile(spawn_pos, shot_dir)
		if projectile != null:
			spawned.append(projectile)

	if summon_duration > 0.0:
		await get_tree().create_timer(summon_duration).timeout
	return spawned

func _state_telegraph(spawned: Array[Area2D]) -> void:
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


func _state_shoot(spawned: Array[Area2D]) -> void:
	for projectile in spawned:
		projectile.shoot()

func _state_vulnerable_wait() -> void:
	modulate = Color(1.0, 0.8, 0.8, 1.0)
	while has_active_projectiles() and _hp > 0:
		await get_tree().process_frame
	modulate = Color(1, 1, 1, 1)

func _spawn_earth_projectile(spawn_position: Vector2, direction: Vector2) -> Area2D:
	var projectile_instance := EARTH_PROJECTILE_SCENE.instantiate()
	if projectile_instance == null or not (projectile_instance is Area2D):
		return null

	var projectile := projectile_instance as Area2D
	projectile.top_level = true
	projectile.global_position = spawn_position

	projectile.set("damage", attack_damage)
	projectile.set("source_element", mage_element)
	projectile.set("owner_mage", self)
	projectile.set("launch_direction", direction.normalized())
	projectile.set("base_speed", projectile_speed)

	get_tree().current_scene.add_child(projectile)
	register_projectile(projectile)
	return projectile
