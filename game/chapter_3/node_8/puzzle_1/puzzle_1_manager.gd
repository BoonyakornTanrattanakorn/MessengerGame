extends Node2D

signal puzzle_completed

@export var exit_warp: Node2D

var _plates: Array[Node2D] = []
var _correct_count := 0

func _ready() -> void:
	await get_tree().process_frame
	for child in get_children():
		if child.is_in_group("pressure_plate"):
			_plates.append(child)
			child.plate_activated.connect(_on_plate_activated)
			child.plate_deactivated.connect(_on_plate_deactivated)

	if not exit_warp:
		exit_warp = get_parent().get_node_or_null("ExitWarp")
	if exit_warp:
		exit_warp.hide()

func _on_plate_activated(plate: Node2D) -> void:
	if plate.is_correct_plate:
		_correct_count += 1
		_check_completion()

func _on_plate_deactivated(plate: Node2D) -> void:
	if plate.is_correct_plate and _correct_count > 0:
		_correct_count -= 1

func _check_completion() -> void:
	var correct_total := _plates.filter(func(p): return p.is_correct_plate).size()
	if _correct_count >= correct_total:
		puzzle_completed.emit()
		Chap3Node8State.complete_puzzle(1)
		if exit_warp:
			exit_warp.show()
