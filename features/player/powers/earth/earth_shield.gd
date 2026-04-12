extends Area2D
class_name EarthShield

@export var max_hp: int = 2
@export var duration: float = 5.0
@export var cooldown: float = 3.0

var current_hp: int = 0
var is_active: bool = false
var cooldown_timer: float = 0.0
var duration_timer: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	set_active(false)
	set_process(false)
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer -= delta

	if is_active and duration_timer > 0.0:
		duration_timer -= delta
		if duration_timer <= 0.0:
			break_shield()


func activate() -> void:
	if cooldown_timer > 0.0:
		return

	current_hp = max_hp
	duration_timer = duration
	set_active(true)
	set_process(true)
	if animated_sprite != null:
		animated_sprite.play("default")


func take_damage(amount: int = 1) -> void:
	if not is_active:
		return

	current_hp = max(0, current_hp - max(1, amount))
	if current_hp <= 0:
		break_shield()


func break_shield() -> void:
	if not is_active:
		return

	set_active(false)
	current_hp = 0
	cooldown_timer = cooldown


func set_active(active: bool) -> void:
	is_active = active
	visible = active
	if animated_sprite != null:
		animated_sprite.visible = active
	if collision_shape != null:
		collision_shape.set_deferred("disabled", not active)
	# Defer monitoring state changes to avoid physics flush-query errors.
	set_deferred("monitoring", active)
	set_deferred("monitorable", active)


func try_absorb_projectile(projectile: Area2D) -> bool:
	if projectile == null:
		return false
	if not is_active:
		return false
	if not projectile.is_in_group("enemy_projectile"):
		return false

	if projectile.has_meta("shield_consumed"):
		return true

	var dmg = projectile.get("damage")
	var damage_amount := int(dmg) if dmg != null else 1
	projectile.set_meta("shield_consumed", true)
	take_damage(damage_amount)
	projectile.queue_free()
	return true


func _on_area_entered(area: Area2D) -> void:
	try_absorb_projectile(area)
