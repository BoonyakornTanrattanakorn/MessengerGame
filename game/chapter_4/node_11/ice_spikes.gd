extends Area2D

@export var speed: float = 220.0
@export var damage: int = 1
@export var lifetime: float = 2.0
@export var source_element: String = "ice"

var direction: Vector2 = Vector2.LEFT
var _elapsed_time: float = 0.0
var _has_hit: bool = false


func _ready() -> void:
	add_to_group("enemy_projectile")
	area_entered.connect(_on_area_entered)
	if direction.length_squared() <= 0.0001:
		direction = Vector2.LEFT
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction.normalized() * speed * delta
	_elapsed_time += delta
	if _elapsed_time >= lifetime:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _has_hit:
		return
	# EarthShield handles enemy_projectile absorption on its own Area2D callback.
	if area is EarthShield:
		return
	if area.is_in_group("player_hurtbox"):
		_apply_player_damage(area)


func _apply_player_damage(target: Node) -> void:
	var player: Node = target
	if target.is_in_group("player_hurtbox"):
		player = target.get_parent()

	if player == null:
		return

	# Keep shield priority: active EarthShield should consume this projectile first.
	var shield := player.find_child("EarthShield", true, false)
	if shield is EarthShield and (shield as EarthShield).is_active:
		return

	var health_component := player.get_node_or_null("HealthComponent") as HealthComponent
	if health_component == null:
		return

	_has_hit = true
	# Prevent Player hurtbox callback from applying damage again.
	set_meta("shield_consumed", true)
	health_component.take_damage(damage)
	queue_free()
