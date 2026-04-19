# RockFall.gd
extends Node2D

signal rock_exploded

const OUTER_RADIUS: float = 60.0   # warning zone radius
const INNER_RADIUS: float = 20.0   # fill circle radius
const DURATION: float = 2.0        # time before explosion
const DAMAGE: int = 1

var timer: float = 0.0
var progress: float = 0.0          # 0.0 to 1.0
var has_exploded: bool = false
var player_ref = null

# Colors
const COLOR_OUTER_RING = Color(1.0, 0.2, 0.2, 0.5)
const COLOR_INNER_RING = Color(1.0, 0.0, 0.0, 0.3)
const COLOR_FILL       = Color(1.0, 0.1, 0.1, 0.85)
const COLOR_RING_LINE  = Color(1.0, 0.3, 0.3, 0.9)

func _ready():
	player_ref = get_tree().root.find_child("Player", true, false)

func _process(delta):
	if has_exploded:
		return
	timer += delta
	progress = clamp(timer / DURATION, 0.0, 1.0)
	queue_redraw()

	if progress >= 1.0:
		_explode()

func _draw():
	# Outer ring — danger zone
	draw_arc(Vector2.ZERO, OUTER_RADIUS, 0, TAU, 64, COLOR_RING_LINE, 2.0)
	draw_circle(Vector2.ZERO, OUTER_RADIUS, COLOR_OUTER_RING)

	# Inner ring border
	draw_arc(Vector2.ZERO, INNER_RADIUS, 0, TAU, 32, COLOR_RING_LINE, 2.5)

	# Fill arc — grows as timer progresses
	if progress > 0:
		draw_arc(
			Vector2.ZERO,
			INNER_RADIUS - 4,
			-PI / 2,                    # start from top
			-PI / 2 + TAU * progress,   # fill clockwise
			64,
			COLOR_FILL,
			(INNER_RADIUS - 4) * 2      # thick enough to fill
		)

func _explode():
	has_exploded = true
	queue_redraw()

	if player_ref != null:
		var dist = global_position.distance_to(player_ref.global_position)
		if dist <= OUTER_RADIUS:
			# Use health_component instead of take_damage directly
			var health_comp = player_ref.get_node_or_null("HealthComponent")
			if health_comp:
				health_comp.take_damage(DAMAGE)
				print("[RockFall] Player hit!")
			else:
				print("[RockFall] ERROR: HealthComponent not found on player")
		else:
			print("[RockFall] Player safe — distance: ", dist)

	rock_exploded.emit()
	await get_tree().create_timer(0.2).timeout
	queue_free()
