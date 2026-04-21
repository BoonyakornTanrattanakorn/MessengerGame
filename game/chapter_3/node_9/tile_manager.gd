extends Node2D

signal phase_complete(phase: int)
signal boss_defeated

const CORRECT_PLATES = {
	1: [2,3,5,6,7,8,10,11,13,14,15,16,20,23,24,26,27,28,29,30,31,32,33,34,35,38,43,46,47,48],      # phase 1 correct plates
	2: [65,66,67,68,69,71,73,77,78,79,80,33,36,37,38,40,43,47,50,54,55,58,59,60,61,62,63,64],  # phase 2 correct plates
	3: [114,115,117,120,121,124,126,127,97,100,102,103,106,107,109,112,81,83,86,88,90,92,94,96],      # phase 3 correct plates
}

var current_phase: int = 1
var plates: Dictionary = {}       # id -> PressurePlate node
var stepped_correct: Array = []
var total_correct: int = 0

func _ready():
	_link_plates()
	_set_phase(1)

func _link_plates():
	for i in range(1, 129):
		# Find each plate by name
		var plate = get_tree().root.find_child(
			"PressurePlate" + str(i), true, false
		)
		if plate == null:
			print("[TileManager] WARNING: PressurePlate", i, " not found!")
			continue
		plate.plate_id = i
		plate.plate_activated.connect(_on_plate_activated)
		plate.plate_deactivated.connect(_on_plate_deactivated)
		plates[i] = plate
	print("[TileManager] Linked ", plates.size(), " plates")

func _set_phase(phase: int):
	current_phase = phase
	stepped_correct.clear()
	total_correct = CORRECT_PLATES[phase].size()

	# Reset all plates visually
	for plate in plates.values():
		plate.reset()

	# Mark correct plates
	for plate in plates.values():
		plate.set_correct(plate.plate_id in CORRECT_PLATES[phase])

	print("[TileManager] Phase ", phase, " started — need plates: ", CORRECT_PLATES[phase])

func _on_plate_activated(id: int):
	if id in CORRECT_PLATES[current_phase]:
		if id not in stepped_correct:
			stepped_correct.append(id)
			stepped_correct.sort()
			print("[TileManager] Correct plates so far: ", stepped_correct)
	# Check win condition every time a plate activates
	_check_win_condition()

func _on_plate_deactivated(id: int):
	if id in stepped_correct:
		stepped_correct.erase(id)
		print("[TileManager] Plate ", id, " removed — correct plates: ", stepped_correct)


func _on_phase_complete():
	print("[TileManager] Phase ", current_phase, " complete!")
	phase_complete.emit(current_phase)
	if current_phase >= 3:
		boss_defeated.emit()
	else:
		await get_tree().create_timer(1.5).timeout
		_set_phase(current_phase + 1)

func _check_win_condition():
	# Check all correct plates are active
	for id in CORRECT_PLATES[current_phase]:
		if id not in stepped_correct:
			return

	# Check NO wrong plates are glowing
	for id in plates:
		if plates[id].is_glowing and id not in CORRECT_PLATES[current_phase]:
			print("[TileManager] Wrong plate ", id, " is still glowing — blocked!")
			return

	# All correct, no wrong — phase complete!
	_on_phase_complete()
