extends Area2D

@export var lion_guard_path: NodePath
@export var red_gem_path: NodePath

@export var save_id = "bell_trigger"
@export var save_scope = "scene"

var used := false

func _ready() -> void:
	add_to_group("savable")
	area_entered.connect(_on_area_entered)
	set_meta("no_interact", true)

func _on_area_entered(area: Area2D) -> void:
	print("Bell touched by: ", area.name)

	if used:
		return

	if not area.is_in_group("wind_wave"):
		return

	used = true
	print("Bell triggered by wind wave")

	var lion = get_node_or_null(lion_guard_path)
	if lion and lion.has_method("scare_and_leave"):
		lion.scare_and_leave()

	var gem = get_node_or_null(red_gem_path)
	if gem and gem.has_method("unlock_pickup"):
		gem.unlock_pickup()

	area.queue_free()
	
func save():
	return {
		"used" : used
	}
	
func load_data(data):
	used = data.get("used", used)
	
	if used:
		var lion = get_node_or_null(lion_guard_path)
		if lion and lion.has_method("scare_and_leave"):
			lion.scare_and_leave()

		var gem = get_node_or_null(red_gem_path)
		if gem and gem.has_method("unlock_pickup"):
			gem.unlock_pickup()
	
