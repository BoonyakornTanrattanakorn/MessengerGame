extends Area2D
class_name Fire_heavy

var speed = 180.0
var direction = Vector2.RIGHT
var damage = 3
var source_element: String = "fire"
var blast_range = 60.0
var travel_distance = 200.0
var traveled = 0.0
var has_exploded = false

func _ready() -> void:
	add_to_group("fire_reflector")

func _physics_process(delta):
	if has_exploded:
		return
	var step = direction * speed * delta
	position += step
	traveled += step.length()
	if traveled >= travel_distance:
		explode()

func _belongs_to_player(node: Node) -> bool:
	if node == null:
		return false
	if node.is_in_group("player"):
		return true
	var parent := node.get_parent()
	while parent != null:
		if parent.is_in_group("player"):
			return true
		parent = parent.get_parent()
	return false

func explode():
	has_exploded = true
	# damage enemies in blast_range
	for body in get_tree().get_nodes_in_group("enemy"):
		if global_position.distance_to(body.global_position) <= blast_range:
			if body.has_method("take_damage"):
				body.take_damage(damage, source_element)
	# visual flash — you can add a brief AnimatedSprite here
	queue_free()

func _on_body_entered(body):
	if _belongs_to_player(body):
		return
	if not has_exploded:
		explode()

	queue_free()
