extends Node
class_name HealthComponent

signal health_changed(value: int)

@export var max_hp: int = 3
var hp: int = max_hp
var is_invincible: bool = false
var invincible_timer: float = 0.0
var invincible_duration: float = 1.0

func _ready():
	hp = max_hp

func take_damage(amount: int):
	if is_invincible:
		return
	hp -= amount
	if hp <= 0:
		hp = 0
	is_invincible = true
	invincible_timer = invincible_duration
	emit_signal("health_changed", hp)

func heal(amount: int):
	hp = min(hp + amount, max_hp)
	emit_signal("health_changed", hp)

func increase_max_hp(amount: int = 1) -> void:
	max_hp += amount
	heal(amount)
	emit_signal("health_changed", hp)

func _process(delta: float):
	if is_invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			is_invincible = false
			
