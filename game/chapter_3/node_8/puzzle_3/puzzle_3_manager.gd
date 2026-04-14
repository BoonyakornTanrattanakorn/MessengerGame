extends Node2D

signal puzzle_completed

@export var guardian: Node2D
@export var exit_warp: Node2D

func _ready() -> void:
	await get_tree().process_frame

	if not guardian:
		guardian = get_parent().get_node_or_null("StoneGuardian")
	if not exit_warp:
		exit_warp = get_parent().get_node_or_null("ExitWarp")

	if exit_warp:
		exit_warp.hide()

	if guardian:
		guardian.guardian_defeated.connect(_on_guardian_defeated)

func activate_guardian() -> void:
	if guardian:
		guardian.set_physics_process(true)

func _on_guardian_defeated() -> void:
	puzzle_completed.emit()
	Chap3Node8State.complete_puzzle(3)
	if exit_warp:
		exit_warp.show()
