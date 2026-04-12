extends RefCounted
class_name MageTurnComponent

var _owner: Node = null

static var _turn_roster: Array = []
static var _turn_index: int = 0
static var _turn_pause: float = 0.0
static var _last_turn_frame: int = -1

func _init(owner: Node) -> void:
	_owner = owner

func register_mage() -> void:
	if _turn_roster.has(_owner):
		return
	_turn_roster.append(_owner)

func unregister_mage() -> void:
	var idx := _turn_roster.find(_owner)
	if idx == -1:
		return
	_turn_roster.remove_at(idx)
	if _turn_roster.is_empty():
		_turn_index = 0
		_turn_pause = 0.0
		return
	if idx < _turn_index:
		_turn_index -= 1
	_turn_index %= _turn_roster.size()

func update_turn_state(delta: float) -> void:
	var frame := Engine.get_physics_frames()
	if frame == _last_turn_frame:
		return
	_last_turn_frame = frame

	_turn_roster = _turn_roster.filter(func(m): return m != null and is_instance_valid(m) and m._hp > 0)
	if _turn_roster.is_empty():
		_turn_index = 0
		_turn_pause = 0.0
		return

	_turn_index %= _turn_roster.size()
	_turn_pause = max(0.0, _turn_pause - delta)

func is_my_turn() -> bool:
	if _turn_roster.is_empty() or _turn_pause > 0.0:
		return false
	if _turn_index < 0 or _turn_index >= _turn_roster.size():
		return false
	return _turn_roster[_turn_index] == _owner

func pass_turn(delay: float = 0.35) -> void:
	if _turn_roster.is_empty():
		return
	var my_index := _turn_roster.find(_owner)
	if my_index == -1:
		return
	_turn_index = (my_index + 1) % _turn_roster.size()
	_turn_pause = max(0.0, delay)
