extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 120.0
var damage: int = 1
var max_distance: float = 300.0
var traveled: float = 0.0

func _ready() -> void:
	add_to_group("enemy_projectile")
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	var step := direction * speed * delta
	position += step
	traveled += step.length()
	if traveled >= max_distance:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_node("HealthComponent"):
			body.get_node("HealthComponent").take_damage(damage)
		elif body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	elif not body.is_in_group("enemy"):
		queue_free()
