extends Area2D

@export var next_level_path: String = "res://game/chapter_4/node_11/tower_2nd_flr.tscn"
@export var spawn_position_in_next_level: Vector2 = Vector2(307, 133)
@export var facing_direction_on_warp: Vector2 = Vector2(0, 1)

const WARP_COOLDOWN_MS := 700
const WARP_COOLDOWN_KEY := "node11_warp_cooldown_until"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return

	if not _begin_warp_cooldown():
		return

	SaveManager.save_game()
	get_tree().current_scene.call_deferred(
		"load_level",
		next_level_path,
		spawn_position_in_next_level,
		facing_direction_on_warp
	)


func _begin_warp_cooldown() -> bool:
	var tree := get_tree()
	var now := Time.get_ticks_msec()
	var cooldown_until: int = int(tree.get_meta(WARP_COOLDOWN_KEY, 0))

	if now < cooldown_until:
		return false

	tree.set_meta(WARP_COOLDOWN_KEY, now + WARP_COOLDOWN_MS)
	return true
