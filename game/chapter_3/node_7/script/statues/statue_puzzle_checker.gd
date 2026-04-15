class_name StatuePuzzleChecker

static func is_puzzle_complete(scene_tree: SceneTree) -> bool:
	var slots = scene_tree.get_nodes_in_group("statue_interact")

	if slots.is_empty():
		return false

	for slot in slots:
		# Slot must be occupied
		if not slot.has_meta("occupied") or slot.get_meta("occupied") == false:
			return false

		# Slot must have a statue placed on it
		if not slot.has_meta("placed_statue_name"):
			return false

		# The placed statue must match what the slot expects
		var placed = slot.get_meta("placed_statue_name")
		var expected = slot.get("expected_statue")

		if placed != expected:
			return false

	return true


static func get_puzzle_state(scene_tree: SceneTree) -> Dictionary:
	var slots = scene_tree.get_nodes_in_group("statue_interact")
	var result = {
		"total": slots.size(),
		"correct": 0,
		"incorrect": 0,
		"empty": 0,
	}

	for slot in slots:
		var occupied = slot.has_meta("occupied") and slot.get_meta("occupied") == true
		if not occupied:
			result["empty"] += 1
			continue

		var placed = slot.get_meta("placed_statue_name", "")
		var expected = slot.get("expected_statue")
		if placed == expected:
			result["correct"] += 1
		else:
			result["incorrect"] += 1

	return result
