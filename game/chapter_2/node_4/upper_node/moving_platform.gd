# Platform.gd
extends Area2D

enum MoveDir { UP, DOWN, LEFT, RIGHT }

@export_group("Reception")
@export var platform_group_id: int = 1

@export_group("Behavior Dictionary")
@export var hole_directions: Dictionary = {

}
@export var move_step: float = 32.0

var base_pos: Vector2
var hole_states: Dictionary = {}
var _current_tween: Tween  # ✅ เก็บ reference tween ไว้ kill ก่อนสร้างใหม่

func _ready():
	base_pos = global_position
	add_to_group("platform_group_" + str(platform_group_id))

func update_position_from_hole(incoming_hole_id: int, stone_count: int):
	hole_states[incoming_hole_id] = stone_count
	_calculate_movement()

func _calculate_movement():
	var total_offset = Vector2.ZERO

	for h_id in hole_states.keys():
		var count = hole_states[h_id]
		if count <= 0:
			continue
		if hole_directions.has(h_id):
			var dir_vector = _get_vector_from_enum(hole_directions[h_id])
			total_offset += dir_vector * count

	var target_pos = base_pos + (total_offset * move_step)

	if _current_tween and _current_tween.is_running():
		_current_tween.kill()

	_current_tween = create_tween()
	_current_tween.tween_property(self, "global_position", target_pos, 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

func _get_vector_from_enum(dir: MoveDir) -> Vector2:
	match dir:
		MoveDir.UP:    return Vector2(0, -1)
		MoveDir.DOWN:  return Vector2(0, 1)
		MoveDir.LEFT:  return Vector2(-1, 0)
		MoveDir.RIGHT: return Vector2(1, 0)
	return Vector2.ZERO
