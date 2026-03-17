extends Area2D

@export var tiger_guard_path: NodePath
@export var red_gem_path: NodePath

var used := false

func _ready() -> void:
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

	var tiger = get_node_or_null(tiger_guard_path)
	if tiger and tiger.has_method("scare_and_leave"):
		tiger.scare_and_leave()

	var gem = get_node_or_null(red_gem_path)
	if gem and gem.has_method("unlock_pickup"):
		gem.unlock_pickup()

	area.queue_free()
