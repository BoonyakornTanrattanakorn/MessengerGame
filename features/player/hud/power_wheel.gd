@tool
class_name PowerWheel
extends Container

@export var radius: float = 120.0
@export var start_angle_deg: float = 45
@export var clockwise: bool = true
@export var center_offset: Vector2 = Vector2.ZERO
@export var min_select_distance: float = 24.0
@export var hover_scale: float = 2.0
@export var angle_offset_deg: float = -45.0
@export var pivot: Vector2 = Vector2(32, 32)

signal selection_changed(index)
signal element_selected(index)

var _child_controls: Array = []
var _hover_index: int = -1

func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_arrange_children()
	elif what == NOTIFICATION_READY:
		set_process(true)

func _arrange_children() -> void:
	var nodes: Array = []
	for c in get_children():
		if c is Control:
			nodes.append(c)

	var count := nodes.size()
	if count == 0:
		return

	var angle_step := TAU / float(count)
	var start = deg_to_rad(start_angle_deg)
	var center = size * 0.5 + center_offset

	_child_controls = nodes
	for i in range(count):
		var idx := i
		var angle = start + angle_step * idx * (1 if clockwise else -1)
		var node = nodes[i]
		var node_size := Vector2.ZERO
		if "size" in node:
			node_size = node.size
		elif node.has_method("get_size"):
			node_size = node.get_size()
		node.pivot_offset = pivot
		# position/size API: use .position for Control in Godot 4
		var pos = center + Vector2(cos(angle), sin(angle)) * radius - node_size * 0.5
		if "position" in node:
			node.position = pos
		elif node.has_method("set_position"):
			node.set_position(pos)

func _process(delta: float) -> void:
	if not visible:
		return

	if _child_controls.size() == 0:
		return

	# Mouse position in local coordinates
	var mpos := get_local_mouse_position()
	var center := size * 0.5 + center_offset
	var rel := mpos - center
	var dist := rel.length()

	var prev_hover := _hover_index
	_hover_index = -1

	if dist >= min_select_distance:
		# compute angle where 0 = up, increasing clockwise
		var angle_rad := atan2(rel.x, -rel.y)
		var deg = rad_to_deg(angle_rad)
		deg = fposmod(deg, 360.0)

		# Map explicit ranges to indices (Wind, Fire, Water, Earth)
		# Wind: 315 - 45 (wrap), Fire: 45 - 135, Water: 135 - 225, Earth: 225 - 315
		if deg >= 315 or deg < 45:
			_hover_index = 0
		elif deg >= 45 and deg < 135:
			_hover_index = 1
		elif deg >= 135 and deg < 225:
			_hover_index = 2
		else:
			_hover_index = 3

	if _hover_index != prev_hover:
		_update_hover_visuals()
		emit_signal("selection_changed", _hover_index)

	# If power_wheel action released while visible, emit element_selected
	if Input.is_action_just_released("power_wheel"):
		emit_signal("element_selected", _hover_index)

func select_current() -> int:
	# explicitly select and emit for the current hover index
	if _hover_index >= 0:
		emit_signal("element_selected", _hover_index)
	return _hover_index

func _update_hover_visuals() -> void:
	for i in range(_child_controls.size()):
		var node = _child_controls[i]
		if i == _hover_index and _hover_index != -1:
			node.scale = Vector2.ONE * hover_scale
			node.z_index = 100
		else:
			node.scale = Vector2.ONE
			node.z_index = 0

func get_selected_index() -> int:
	return _hover_index
