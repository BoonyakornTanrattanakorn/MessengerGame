extends Node2D

signal puzzle_completed

@export var exit_lever: Node2D
@export var exit_warp: Node2D
@export var player_reset_position: Vector2 = Vector2.ZERO

var _traps: Array[Node2D] = []

func _ready() -> void:
	await get_tree().process_frame

	for child in get_children():
		if child.is_in_group("moving_trap"):
			_traps.append(child)
			child.player_hit.connect(_on_player_hit)

	if exit_lever and exit_lever.has_signal("lever_pulled"):
		exit_lever.lever_pulled.connect(_on_lever_pulled)

	if exit_warp:
		exit_warp.hide()

func _on_player_hit(_trap: Node2D) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = player_reset_position

func _on_lever_pulled() -> void:
	puzzle_completed.emit()
	Chap3Node8State.complete_puzzle(3)
	if exit_warp:
		exit_warp.show()
