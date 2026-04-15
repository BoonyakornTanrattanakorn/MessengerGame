extends Area2D

@export var next_level_path: String = "res://game/chapter_3/node_7/node_7.tscn"
@export var spawn_position_in_next_level: Vector2 = Vector2(-190, -15)
@export var facing_direction_on_warp: Vector2 = Vector2.LEFT
@export var animation_fps: float = 12.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var portal_sprite: Sprite2D = $PortalSprite

var _frame_timer := 0.0

func update_portal_state() -> void:
	if Node7State.sandmonster_quest_complete:
		show_portal()
	else:
		hide_portal()

func _ready() -> void:
	add_to_group("portal")
	update_portal_state()

func _process(delta: float) -> void:
	if not visible or portal_sprite == null or portal_sprite.hframes <= 1 or animation_fps <= 0.0:
		return

	_frame_timer += delta
	if _frame_timer >= (1.0 / animation_fps):
		_frame_timer = 0.0
		portal_sprite.frame = (portal_sprite.frame + 1) % portal_sprite.hframes

func can_interact() -> int:
	return 0

func activate() -> void:
	if not visible:
		return
	SaveManager.save_game()
	get_tree().current_scene.call_deferred(
		"load_level",
		next_level_path,
		spawn_position_in_next_level,
		facing_direction_on_warp
	)

func show_portal() -> void:
	show()
	remove_meta("no_interact")
	if collision_shape:
		collision_shape.disabled = false

func hide_portal() -> void:
	hide()
	set_meta("no_interact", true)
	if collision_shape:
		collision_shape.disabled = true
	if portal_sprite:
		portal_sprite.frame = 0
	_frame_timer = 0.0
