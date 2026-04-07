extends HBoxContainer

@onready var health_middle_template = $HealthDisplayTemplate/HealthMiddle
@onready var health_end_template = $HealthDisplayTemplate/HealthEnd

@onready var hp_bar = $VBoxContainer/HPBar

func _ready():
	pass

func set_max_health(max_hp: int):
	# Wait until hp_bar is ready
	if hp_bar == null:
		await ready
	if health_middle_template == null or health_end_template == null:
		push_error("Health templates not found under HealthDisplay")
		return
	for child in hp_bar.get_children():
		if child.is_in_group("health_bar"):
			hp_bar.remove_child(child)
			child.free()
	for i in range(max_hp - 1):
		var health = health_middle_template.duplicate()
		health.name = "health_middle_%d" % i
		health.add_to_group("health_bar")
		hp_bar.add_child(health)
	var health = health_end_template.duplicate()
	health.name = "health_end"
	health.add_to_group("health_bar")
	hp_bar.add_child(health)

func _get_health_children() -> Array:
	var healths: Array = []
	if hp_bar == null:
		return healths
	for child in hp_bar.get_children():
		if child.is_in_group("health_bar") and child.has_method("update_sprite"):
			healths.append(child)
	return healths

func update_health(cur_health: int):
	var healths = _get_health_children()
	if healths.is_empty():
		return
	cur_health = clamp(cur_health, 0, healths.size())
	for i in range(cur_health):
		healths[i].update_sprite(true)
	for i in range(cur_health, healths.size()):
		healths[i].update_sprite(false)
