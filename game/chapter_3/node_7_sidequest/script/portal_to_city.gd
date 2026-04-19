extends Warp

# Animation variables from your portal file
@export var animation_fps: float = 12.0
@onready var portal_sprite: Sprite2D = $PortalSprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _frame_timer := 0.0

func _ready() -> void:
	# 1. Add to group so Node7State can find it
	add_to_group("portal")
	
	# 2. Set the destination (Warp variables)
	next_level_path = "res://game/chapter_3/node_7/scenes/node_7.tscn"
	spawn_position_in_next_level = Vector2(5000, 1741)
	facing_direction_on_warp = Vector2.LEFT
	
	# 3. Connect the signal (Warp already does this, but we ensure it's here)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	# 4. Check if the portal should be visible or hidden right now
	update_portal_state()

# This is called by Node7State via call_group
func update_portal_state() -> void:
	if Node7State.sandmonster_quest_complete:
		show_portal()
	else:
		hide_portal()

# We "override" the Warp's _on_body_entered to add a visibility check
func _on_body_entered(body: Node) -> void:
	# If the portal is hidden, don't let the player warp!
	if not visible:
		return
	
	# Call the logic from the base Warp class
	super._on_body_entered(body)

func _process(delta: float) -> void:
	if not visible or portal_sprite == null or portal_sprite.hframes <= 1:
		return

	_frame_timer += delta
	if _frame_timer >= (1.0 / animation_fps):
		_frame_timer = 0.0
		portal_sprite.frame = (portal_sprite.frame + 1) % portal_sprite.hframes

func show_portal() -> void:
	show()
	if collision_shape:
		collision_shape.set_deferred("disabled", false)

func hide_portal() -> void:
	hide()
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
