extends Area2D

@export var required_attribute: String = "wind"
@export var tiger_guard_path: NodePath
@export var red_gem_path: NodePath

var used := false

func can_interact() -> int:
	return 0

func major_activate(player) -> void:
	if used:
		return

	if player == null:
		return

	if player.playerAttribute != required_attribute:
		print("Need attribute: ", required_attribute)
		return

	used = true
	print("Bell trigger activated")

	var tiger = get_node_or_null(tiger_guard_path)
	if tiger and tiger.has_method("scare_and_leave"):
		tiger.scare_and_leave()

	var gem = get_node_or_null(red_gem_path)
	if gem and gem.has_method("unlock_pickup"):
		gem.unlock_pickup()

	set_meta("no_interact", true)
