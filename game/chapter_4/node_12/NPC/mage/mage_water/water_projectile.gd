extends Node12MageBaseProjectile

@export var telegraph_infinite_length: float = 2000.0
@export var telegraph_line_width: float = 4.0
@export var telegraph_line_color: Color = Color(0.64, 0.88, 1.0, 0.8)
@export var telegraph_warning_color: Color = Color(1.0, 0.35, 0.35, 0.95)
@export var telegraph_arrow_spacing: float = 50.0
@export var telegraph_arrow_length: float = 10.0
@export var telegraph_arrow_width: float = 5.0
@export var telegraph_arrow_speed: float = 100.0

var _warning_active: bool = false

func _process(_delta: float) -> void:
	if _telegraphing:
		queue_redraw()

func _ready() -> void:
	if source_element == "":
		source_element = "water"
	rotation = launch_direction.normalized().angle()
	super._ready()

func shoot() -> void:
	_warning_active = false
	super.shoot()
	queue_redraw()

func set_telegraph(enabled: bool) -> void:
	super.set_telegraph(enabled)
	queue_redraw()

func _draw() -> void:
	if not _telegraphing:
		return
	var world_end := global_position + launch_direction.normalized() * telegraph_infinite_length
	var line_end := to_local(world_end)
	var line_color := telegraph_warning_color if _warning_active else telegraph_line_color
	draw_line(Vector2.ZERO, line_end, line_color, telegraph_line_width)

	var line_length := line_end.length()
	if line_length <= 0.001:
		return

	var dir := line_end / line_length
	var perp := dir.orthogonal()
	var safe_spacing := maxf(24.0, telegraph_arrow_spacing)
	var travel_offset := fmod(float(Time.get_ticks_msec()) * 0.001 * telegraph_arrow_speed, safe_spacing)
	var arrow_color := telegraph_warning_color

	var distance := travel_offset
	while distance < line_length:
		if distance >= telegraph_arrow_length:
			var center := dir * distance
			var tip := center + dir * (telegraph_arrow_length * 0.5)
			var tail := center - dir * (telegraph_arrow_length * 0.5)
			var left := tail + perp * (telegraph_arrow_width * 0.5)
			var right := tail - perp * (telegraph_arrow_width * 0.5)
			draw_colored_polygon(PackedVector2Array([tip, left, right]), arrow_color)
		distance += safe_spacing

func play_pre_shoot_warning(duration: float = 0.08) -> void:
	if duration <= 0.0:
		return
	if SFXManager != null:
		SFXManager.play_event("mage.projectile.warn")
	_warning_active = true
	queue_redraw()
	await get_tree().create_timer(duration).timeout
	_warning_active = false
	queue_redraw()

func _update_guidance(_delta: float) -> void:
	# Water projectile intentionally keeps a straight, high-speed trajectory.
	pass

func _get_telegraph_tint() -> Color:
	return Color(0.64, 0.88, 1.0, 0.78)

func _get_reflected_tint() -> Color:
	return Color(0.5, 0.74, 1.0, 1.0)
