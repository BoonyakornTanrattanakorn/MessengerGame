# TileManager.gd
extends Node2D

signal phase_complete(phase: int)
signal boss_defeated

# Define correct plates for each phase
# Change these IDs to match your puzzle design
const CORRECT_PLATES = {
	1: [2,3,5,6,7,8,10,11,13,14,15,16,20,23,24,26,27,28,29,30,31,32,33,34,35,38,43,46,47,48],      # phase 1 correct plates
	2: [1,2,3,4,5,7,9,13,14,15,16,17,20,21,22,24,27,31,34,38,39,42,43,44,45,46,47,48],  # phase 2 correct plates
	3: [2,3,5,8,9,12,14,15,17,20,22,23,26,27,29,32,33,35,38,40,42,44,46,48],      # phase 3 correct plates
}

const PLATE_COLS = 16
const PLATE_ROWS = 3
const PLATE_SIZE = Vector2(48, 48)
const PLATE_GAP = Vector2(4, 4)

var current_phase: int = 1
var plates: Array = []  # all 48 PressurePlate nodes
var stepped_correct: Array = []
var total_correct: int = 0

@export var plate_scene: PackedScene = preload("res://game/chapter_3/node_3/PressurePlate.tscn")

func _ready():
	_build_plates()
	_set_phase(1)

func _build_plates():
	for row in PLATE_ROWS:
		for col in PLATE_COLS:
			var plate = plate_scene.instantiate()
			var id = row * PLATE_COLS + col + 1  # 1-48
			plate.plate_id = id
			plate.position = Vector2(
				col * (PLATE_SIZE.x + PLATE_GAP.x),
				row * (PLATE_SIZE.y + PLATE_GAP.y)
			)
			plate.plate_stepped.connect(_on_plate_stepped)
			add_child(plate)
			plates.append(plate)

func _set_phase(phase: int):
	current_phase = phase
	stepped_correct.clear()
	total_correct = CORRECT_PLATES[phase].size()

	# Mark correct plates
	for plate in plates:
		var correct = plate.plate_id in CORRECT_PLATES[phase]
		plate.set_correct(correct)

	print("[TileManager] Phase ", phase, " — correct plates: ", CORRECT_PLATES[phase])

func _on_plate_stepped(id: int):
	var correct_list = CORRECT_PLATES[current_phase]
	if id in correct_list and id not in stepped_correct:
		stepped_correct.append(id)
		print("[TileManager] Correct! ", stepped_correct.size(), "/", total_correct)
		if stepped_correct.size() >= total_correct:
			_on_phase_complete()

func _on_phase_complete():
	print("[TileManager] Phase ", current_phase, " complete!")
	phase_complete.emit(current_phase)
	if current_phase >= 3:
		boss_defeated.emit()
	else:
		await get_tree().create_timer(1.5).timeout
		_set_phase(current_phase + 1)

func reset_row(row: int):
	# row 1 = plates 1-16, row 2 = 17-32, row 3 = 33-48
	var start = (row - 1) * PLATE_COLS
	var end = start + PLATE_COLS
	for i in range(start, end):
		plates[i].reset()
	print("[TileManager] Row ", row, " reset")
