extends Area2D

var speed = 400.0
var direction = Vector2.RIGHT
var lifetime = 1.0
var damage = 1
var source_element: String = "wind"

func _ready():
	# สั่งให้ลบตัวเองทิ้งเมื่อครบเวลา
	add_to_group("spell")
	add_to_group("wind_wave")
	add_to_group("wind_reflector")
	await get_tree().create_timer(lifetime).timeout
	queue_free()

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

func _is_water_collider(node: Node) -> bool:
	if node == null:
		return false

	var current: Node = node
	while current != null:
		if current.is_in_group("water"):
			return true
		if current.name.to_lower().contains("water"):
			return true
		current = current.get_parent()

	return false

func _on_body_entered(body):
	if _belongs_to_player(body):
		return
	if _is_water_collider(body):
		return
	if body != null and body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(damage, source_element)
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area == null:
		return
	if _belongs_to_player(area):
		return
	if _is_water_collider(area):
		return

	if area.name.to_lower().contains("bell") and area.has_method("_on_area_entered"):
		area.call("_on_area_entered", self)


	queue_free()
