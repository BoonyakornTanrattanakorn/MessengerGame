# ResetSwitch.gd
extends StaticBody2D

@export var row: int = 1  # set in editor: 1, 2, or 3
var tile_manager: Node = null

func _ready():
	tile_manager = get_tree().root.find_child("TileManager", true, false)
	$InteractionArea.body_entered.connect(_on_area_entered)
	$InteractionArea.body_exited.connect(_on_area_exited)

func can_interact() -> int:
	return 0

func activate():
	if tile_manager:
		tile_manager.reset_row(row)
		print("[Switch] Reset row ", row)

func _on_area_entered(body):
	if body.is_in_group("player"):
		body.interact_with = self

func _on_area_exited(body):
	if body.is_in_group("player") and body.interact_with == self:
		body.interact_with = null
