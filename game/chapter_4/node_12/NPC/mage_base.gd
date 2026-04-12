extends CharacterBody2D
class_name Chapter4MageBase

const MageTurnComponent = preload("res://game/chapter_4/node_12/npc/components/mage_turn_component.gd")
const MageVisualComponent = preload("res://game/chapter_4/node_12/npc/components/mage_visual_component.gd")
const MageProjectileComponent = preload("res://game/chapter_4/node_12/npc/components/mage_projectile_component.gd")

@export var mage_element: String = "earth"
@export var required_reflect_element: String = "wind"
@export var max_hp: int = 3
@export var attack_damage: int = 1
@export var attack_interval: float = 8.0
@export var projectile_speed: float = 100.0
@export var vulnerability_duration: float = 8.0
@export var attack_range: float = 2000.0

var _hp: int = 0
var _attack_cooldown: float = 0.0
var _vulnerability_timer: float = 0.0
var _is_casting: bool = false
var _player_ref: Node = null

var _turn_component
var _visual_component
var _projectile_component

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	_turn_component = MageTurnComponent.new(self)
	_visual_component = MageVisualComponent.new(self)
	_projectile_component = MageProjectileComponent.new(self)

	_hp = max_hp
	add_to_group("enemy")
	_player_ref = _find_player()
	_create_health_bar_visual()
	_update_health_bar_visual()
	_create_barrier_visual()
	_register_in_turn_roster()

func _exit_tree() -> void:
	_unregister_from_turn_roster()

func _physics_process(delta: float) -> void:
	if _hp <= 0:
		return

	_projectile_component.prune_active_projectiles()

	if _vulnerability_timer > 0.0:
		_vulnerability_timer -= delta

	if _attack_cooldown > 0.0:
		_attack_cooldown = max(0.0, _attack_cooldown - delta)

	_update_turn_state(delta)
	if not _is_my_turn():
		return

	if _is_casting:
		return

	if _attack_cooldown > 0.0:
		finish_casting(0.2)
		return

	if _player_ref == null or not is_instance_valid(_player_ref):
		_player_ref = _find_player()
		if _player_ref == null:
			return

	if global_position.distance_to(_player_ref.global_position) > attack_range:
		return

	_is_casting = true
	perform_attack_pattern()

func perform_attack_pattern() -> void:
	# Implement in child scripts.
	finish_casting(attack_interval)

func begin_vulnerability_window(duration_override: float = -1.0) -> void:
	var duration := vulnerability_duration if duration_override < 0.0 else duration_override
	_vulnerability_timer = max(_vulnerability_timer, duration)
	modulate = Color(1.0, 0.8, 0.8)

func finish_casting(next_cooldown: float = attack_interval) -> void:
	_attack_cooldown = max(0.1, next_cooldown)
	_is_casting = false
	_pass_turn(0.35)
	if _vulnerability_timer <= 0.0:
		modulate = Color(1, 1, 1)

func _process(delta: float) -> void:
	if not _is_vulnerable() and modulate != Color(1, 1, 1):
		modulate = Color(1, 1, 1)
	_update_barrier_visual(delta)

func take_damage(amount: int = 1, source_element: String = "") -> void:
	# Puzzle rule: direct player attacks never damage mages.
	return

func receive_reflected_hit(amount: int = 1, source_element: String = "wind") -> void:
	if _hp <= 0:
		return
	if not _is_vulnerable():
		return
	if required_reflect_element != "" and source_element != required_reflect_element:
		return
	_hp -= max(1, amount)
	_update_health_bar_visual()
	if _hp <= 0:
		die()

func die() -> void:
	_hp = 0
	_update_health_bar_visual()
	_unregister_from_turn_roster()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	await tween.finished
	queue_free()

func spawn_projectile(direction: Vector2, speed_scale: float = 1.0, life_time: float = 2.2, radius: float = 9.0, tint: Color = Color(1, 1, 1)) -> void:
	_projectile_component.spawn_projectile(direction, speed_scale, life_time, radius, tint)

func spawn_projectile_from_position(spawn_position: Vector2, direction: Vector2, speed_scale: float = 1.0, life_time: float = 2.2, radius: float = 9.0, tint: Color = Color(1, 1, 1)) -> void:
	_projectile_component.spawn_projectile_from_position(spawn_position, direction, speed_scale, life_time, radius, tint)

func spawn_delayed_burst(position: Vector2, delay: float, ring_count: int, speed_scale: float, tint: Color) -> void:
	await _projectile_component.spawn_delayed_burst(position, delay, ring_count, speed_scale, tint)

func summon_falling_strike(target_position: Vector2, delay: float = 0.7, radius: float = 14.0, tint: Color = Color(1, 1, 1), fall_height: float = 120.0) -> void:
	await _projectile_component.summon_falling_strike(target_position, delay, radius, tint, fall_height)

func _drive_projectile_async_component(projectile: Area2D, life_time: float) -> void:
	if _projectile_component == null:
		return
	await _projectile_component.drive_projectile_async(projectile, life_time)

func predict_player_position(lead_time: float = 0.45) -> Vector2:
	if _player_ref == null or not is_instance_valid(_player_ref):
		_player_ref = _find_player()
	if _player_ref == null:
		return global_position + Vector2(0, 64)

	var velocity := Vector2.ZERO
	if "velocity" in _player_ref:
		velocity = _player_ref.velocity
	return _player_ref.global_position + velocity * lead_time

func get_direction_to_player() -> Vector2:
	if _player_ref == null or not is_instance_valid(_player_ref):
		_player_ref = _find_player()
	if _player_ref == null:
		return Vector2.DOWN
	return (_player_ref.global_position - global_position).normalized()

func _register_in_turn_roster() -> void:
	_turn_component.register_mage()

func _unregister_from_turn_roster() -> void:
	if _turn_component != null:
		_turn_component.unregister_mage()

func _update_turn_state(delta: float) -> void:
	_turn_component.update_turn_state(delta)

func _is_my_turn() -> bool:
	return _turn_component.is_my_turn()

func _pass_turn(delay: float = 0.35) -> void:
	_turn_component.pass_turn(delay)

func _find_player() -> Node:
	var root := get_tree().current_scene
	if root == null:
		return null
	var by_name := root.find_child("Player", true, false)
	if by_name != null:
		return by_name
	return root.find_child("player", true, false)

func _has_active_projectiles() -> bool:
	return _projectile_component.has_active_projectiles()

func _is_vulnerable() -> bool:
	return _vulnerability_timer > 0.0 or _has_active_projectiles()

func _create_barrier_visual() -> void:
	_visual_component.create_barrier_visual()

func _update_barrier_visual(delta: float) -> void:
	_visual_component.update_barrier_visual(delta, _is_vulnerable(), _hp)

func _create_health_bar_visual() -> void:
	_visual_component.create_health_bar_visual()

func _update_health_bar_visual() -> void:
	_visual_component.update_health_bar_visual(_hp, max_hp)
