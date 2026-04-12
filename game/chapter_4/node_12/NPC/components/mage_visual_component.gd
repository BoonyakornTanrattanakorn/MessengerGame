extends RefCounted
class_name MageVisualComponent

var _owner: Node2D = null
var _barrier_phase: float = 0.0

var _barrier_root: Node2D = null
var _barrier_ring: Line2D = null
var _barrier_fill: Polygon2D = null

var _health_root: Node2D = null
var _health_bg: Polygon2D = null
var _health_fill: Polygon2D = null

func _init(owner: Node2D) -> void:
	_owner = owner

func create_barrier_visual() -> void:
	_barrier_root = Node2D.new()
	_barrier_root.name = "InvincibleBarrier"
	_barrier_root.visible = true
	_owner.add_child(_barrier_root)

	_barrier_fill = Polygon2D.new()
	_barrier_fill.color = Color(0.55, 0.85, 1.0, 0.13)
	_barrier_fill.polygon = _build_circle_points(26.0, 28)
	_barrier_root.add_child(_barrier_fill)

	_barrier_ring = Line2D.new()
	_barrier_ring.width = 2.5
	_barrier_ring.default_color = Color(0.65, 0.95, 1.0, 0.8)
	_barrier_ring.closed = true
	_barrier_ring.points = _build_circle_points(28.0, 28)
	_barrier_root.add_child(_barrier_ring)

func update_barrier_visual(delta: float, is_vulnerable: bool, hp: int) -> void:
	if _barrier_root == null:
		return

	# Barrier is visible when mage is invincible (outside attack window).
	var invincible := (not is_vulnerable) and hp > 0
	_barrier_root.visible = invincible
	if not invincible:
		return

	_barrier_phase += delta * 3.0
	_barrier_root.rotation = sin(_barrier_phase * 0.35) * 0.08
	var pulse := 0.85 + 0.15 * (0.5 + 0.5 * sin(_barrier_phase * 2.0))
	_barrier_root.scale = Vector2.ONE * pulse

	if _barrier_ring != null:
		_barrier_ring.default_color = Color(0.65, 0.95, 1.0, 0.65 + 0.2 * (0.5 + 0.5 * sin(_barrier_phase * 2.4)))
	if _barrier_fill != null:
		_barrier_fill.color = Color(0.55, 0.85, 1.0, 0.08 + 0.08 * (0.5 + 0.5 * sin(_barrier_phase * 1.8)))

func create_health_bar_visual() -> void:
	_health_root = Node2D.new()
	_health_root.name = "HealthBar"
	_health_root.position = Vector2(0, -34)
	_owner.add_child(_health_root)

	var bar_w := 34.0
	var bar_h := 5.0

	_health_bg = Polygon2D.new()
	_health_bg.color = Color(0.1, 0.1, 0.1, 0.85)
	_health_bg.polygon = PackedVector2Array([
		Vector2(-bar_w * 0.5 - 1.0, -bar_h * 0.5 - 1.0),
		Vector2(bar_w * 0.5 + 1.0, -bar_h * 0.5 - 1.0),
		Vector2(bar_w * 0.5 + 1.0, bar_h * 0.5 + 1.0),
		Vector2(-bar_w * 0.5 - 1.0, bar_h * 0.5 + 1.0)
	])
	_health_root.add_child(_health_bg)

	_health_fill = Polygon2D.new()
	_health_fill.color = Color(0.95, 0.25, 0.25, 0.95)
	_health_root.add_child(_health_fill)

func update_health_bar_visual(hp: int, max_hp: int) -> void:
	if _health_root == null or _health_fill == null:
		return

	if hp <= 0:
		_health_root.visible = false
		return

	_health_root.visible = true
	var bar_w := 34.0
	var bar_h := 5.0
	var ratio = clamp(float(hp) / float(max(1, max_hp)), 0.0, 1.0)
	var left := -bar_w * 0.5
	var right = left + bar_w * ratio

	_health_fill.polygon = PackedVector2Array([
		Vector2(left, -bar_h * 0.5),
		Vector2(right, -bar_h * 0.5),
		Vector2(right, bar_h * 0.5),
		Vector2(left, bar_h * 0.5)
	])

func _build_circle_points(radius: float, point_count: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(point_count):
		var t := TAU * float(i) / float(point_count)
		pts.append(Vector2(cos(t), sin(t)) * radius)
	return pts