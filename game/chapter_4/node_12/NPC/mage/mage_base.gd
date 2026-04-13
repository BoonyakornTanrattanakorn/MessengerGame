extends CharacterBody2D
class_name Node12MageBase

enum state {
	WAITING_FOR_TURN,
	PATTERN_ATTACK,
	PROJECTILE_ATTACK
}

@export var mage_element: String = "earth"
@export var required_reflect_element: String = "earth"
@export var max_hp: int = 3
@export var attack_damage: int = 1
@export var attack_interval: float = 1.0
@export var attack_range: float = 2000.0
@export var projectile_speed: float = 220.0

static var _turn_roster: Array[Node12MageBase] = []
static var _turn_index: int = 0

var _hp: int = 0
var _attack_cooldown: float = 0.0
var _is_casting: bool = false
var _player_ref: CharacterBody2D
var _active_projectiles: Array[Area2D] = []

func _ready() -> void:
	_hp = max_hp
	add_to_group("enemy")
	_register_in_turn_roster()
	
	_player_ref = _find_player()
	assert(_player_ref != null, "Can't find player!")

func _exit_tree() -> void:
	_unregister_from_turn_roster()

func _physics_process(delta: float) -> void:
	if _hp <= 0:
		return

	_prune_projectiles()

	if _attack_cooldown > 0.0:
		_attack_cooldown = max(0.0, _attack_cooldown - delta)
		return

	if _is_casting:
		return

	if not _is_my_turn():
		return

	if global_position.distance_to(_player_ref.global_position) > attack_range:
		return

	_is_casting = true
	await perform_attack_pattern()

func perform_attack_pattern() -> void:
	finish_casting(attack_interval)

func begin_casting_state() -> void:
	_is_casting = true

func finish_casting(next_cooldown: float = attack_interval) -> void:
	_attack_cooldown = max(0.0, next_cooldown)
	_is_casting = false
	_pass_turn()

func get_direction_to_player() -> Vector2:
	var dir := _player_ref.global_position - global_position
	if dir.length_squared() <= 0.0001:
		return Vector2.DOWN
	return dir.normalized()

func register_projectile(projectile: Area2D) -> void:
	if projectile == null:
		return
	_active_projectiles.append(projectile)

func has_active_projectiles() -> bool:
	_prune_projectiles()
	return not _active_projectiles.is_empty()

func _prune_projectiles() -> void:
	var pruned: Array[Area2D] = []
	for projectile in _active_projectiles:
		if projectile != null and is_instance_valid(projectile):
			pruned.append(projectile)
	_active_projectiles = pruned

func receive_reflected_hit(amount: int = 1, source_element: String = "") -> void:
	if _hp <= 0:
		return
	if required_reflect_element != "" and source_element != required_reflect_element:
		return
	_hp -= max(1, amount)
	if _hp <= 0:
		die()

func die() -> void:
	_hp = 0
	_unregister_from_turn_roster()
	queue_free()

func _find_player() -> Node2D:
	var root := get_tree().current_scene
	if root == null:
		return null
	var by_name := root.find_child("Player", true, false)
	if by_name != null and by_name is Node2D:
		return by_name
	var lower_name := root.find_child("player", true, false)
	if lower_name != null and lower_name is Node2D:
		return lower_name
	return null

func _register_in_turn_roster() -> void:
	_prune_turn_roster()
	if _turn_roster.has(self):
		return
	_turn_roster.append(self)
	if _turn_roster.size() == 1:
		_turn_index = 0

func _unregister_from_turn_roster() -> void:
	_prune_turn_roster()
	var idx := _turn_roster.find(self)
	if idx == -1:
		return
	_turn_roster.remove_at(idx)
	if _turn_roster.is_empty():
		_turn_index = 0
		return
	if idx < _turn_index:
		_turn_index -= 1
	_turn_index = clampi(_turn_index, 0, _turn_roster.size() - 1)

func _is_my_turn() -> bool:
	_prune_turn_roster()
	if _turn_roster.is_empty():
		return false
	_turn_index = clampi(_turn_index, 0, _turn_roster.size() - 1)
	return _turn_roster[_turn_index] == self

func _pass_turn() -> void:
	_prune_turn_roster()
	if _turn_roster.is_empty():
		return
	_turn_index = (_turn_index + 1) % _turn_roster.size()

func _prune_turn_roster() -> void:
	var pruned: Array[Node12MageBase] = []
	for mage in _turn_roster:
		if mage != null and is_instance_valid(mage) and mage._hp > 0:
			pruned.append(mage)
	_turn_roster = pruned
	if _turn_roster.is_empty():
		_turn_index = 0
	else:
		_turn_index = clampi(_turn_index, 0, _turn_roster.size() - 1)
