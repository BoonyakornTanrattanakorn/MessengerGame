extends Area2D 

@export var platform_id: int = 1
@export var is_upward_type: bool = true 
@export var move_step: float = 32.0

var base_y: float = 0.0 

func _ready():
	base_y = global_position.y
	add_to_group("platform_group_" + str(platform_id))
	add_to_group("platform")

func update_position(stone_count: int):
	var direction = -1 if is_upward_type else 1
	
	var target_y = base_y + (stone_count * move_step * direction)
	
	var tween = create_tween()
	tween.tween_property(self, "global_position:y", target_y, 0.6).set_trans(Tween.TRANS_SINE)
