extends Area2D

@export var speed: float = 300.0
@export var lifetime: float = 5.0
@export var damage: int = 1

var _direction: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("enemy_projectile")
	area_entered.connect(_on_area_entered)

	if lifetime > 0.0:
		await get_tree().create_timer(lifetime).timeout
		if is_inside_tree():
			queue_free()


func initialize(spawn_position: Vector2, direction: Vector2) -> void:
	global_position = spawn_position
	_direction = direction.normalized() if direction.length() > 0.001 else Vector2.LEFT
	rotation = _direction.angle()


func _physics_process(delta: float) -> void:
	global_position += _direction * speed * delta


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox") or area.is_in_group("enemy_projectile"):
		queue_free()
