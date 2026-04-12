extends PanelContainer

@export var player: CharacterBody2D
@export_range(0.05, 1.0, 0.05) var dim_alpha: float = 0.35
@export_range(0.05, 1.0, 0.05) var normal_alpha: float = 1.0
@export_range(1.0, 20.0, 0.5) var fade_speed: float = 10.0
@export var overlap_padding: float = 16.0

@onready var player_icon = $TextureRect2

var _is_dimmed: bool = false
var _alpha_tween: Tween = null
var _player_hurtbox: Node2D = null

func _ready():
	player_icon.pivot_offset = player_icon.size / 2
	modulate.a = normal_alpha

func _process(delta):
	if player == null:
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
		if player == null:
			return

	if _player_hurtbox == null:
		_player_hurtbox = player.get_node_or_null("Hurtbox") as Node2D

	player_icon.rotation = player.last_direction.angle() + PI / 2

	var is_player_under_minimap := _is_player_in_minimap_screen_zone()
	if is_player_under_minimap != _is_dimmed:
		_is_dimmed = is_player_under_minimap
		var target_alpha := dim_alpha if _is_dimmed else normal_alpha
		_tween_alpha(target_alpha)


func _tween_alpha(target_alpha: float) -> void:
	if _alpha_tween != null and _alpha_tween.is_running():
		_alpha_tween.kill()

	var duration := 1.0 / maxf(fade_speed, 0.001)
	_alpha_tween = create_tween()
	_alpha_tween.set_trans(Tween.TRANS_SINE)
	_alpha_tween.set_ease(Tween.EASE_OUT)
	_alpha_tween.tween_property(self, "modulate:a", target_alpha, duration)


func _is_player_in_minimap_screen_zone() -> bool:
	if player == null:
		return false

	var canvas_transform := get_viewport().get_canvas_transform()
	var reference_global_pos := _get_overlap_reference_global_position()
	var player_screen_pos: Vector2 = canvas_transform * reference_global_pos

	var minimap_rect := get_global_rect().grow(overlap_padding)
	return minimap_rect.has_point(player_screen_pos)


func _get_overlap_reference_global_position() -> Vector2:
	if _player_hurtbox != null and is_instance_valid(_player_hurtbox):
		return _player_hurtbox.global_position

	if player != null:
		return player.global_position

	return Vector2.ZERO
