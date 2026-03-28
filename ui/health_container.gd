extends HBoxContainer

const HealthMiddle = preload("res://ui/health_gui/health_middle.tscn")
const HealthEnd = preload("res://ui/health_gui/health_end.tscn")

func _ready() -> void:
	pass

func set_max_health(max_hp: int):
	for i in range(max_hp - 1):
		var health = HealthMiddle.instantiate()
		health.name = "health_middle_%d" % i
		health.add_to_group("health_bar")
		add_child(health)
	var health = HealthEnd.instantiate()
	health.name = "health_end"
	health.add_to_group("health_bar")
	add_child(health)

func _get_health_children() -> Array:
	var healths: Array = []
	for child in get_children():
		if child.is_in_group("health_bar") and child.has_method("update_sprite"):
			healths.append(child)
		elif child.name.to_lower().contains("health") and child.has_method("update_sprite"):
			healths.append(child)
	return healths

func update_health(cur_health: int):
	var healths = _get_health_children()

	# Guard — if children not ready yet, do nothing
	if healths.is_empty():
		return
	# Guard — clamp cur_health to valid range
	cur_health = clamp(cur_health, 0, healths.size())

	for i in range(cur_health):
		healths[i].update_sprite(true)
	for i in range(cur_health, healths.size()):
		healths[i].update_sprite(false)
