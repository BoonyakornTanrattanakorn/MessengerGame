extends Area2D
class_name Fire_small

var speed = 300.0
var direction = Vector2.RIGHT
var damage = 1
var source_element: String = "fire"

func _ready():
	$CollisionShape2D  # make sure you have one
	add_to_group("fire_reflector")
	add_to_group("spell")
	add_to_group("player_projectile")
	connect("body_entered", _on_body_entered)

func _physics_process(delta):
	position += direction * speed * delta

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

func _on_body_entered(body):
	if body == null:
		return
		
	if _belongs_to_player(body):
		return
		
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(damage, source_element)
		queue_free()
		
	queue_free()
