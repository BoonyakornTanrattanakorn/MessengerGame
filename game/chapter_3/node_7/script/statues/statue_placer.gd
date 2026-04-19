class_name StatuePlacer

static func place_statue_on_platform(statue_name: String, player: Node2D) -> bool:
	var interact_zones = player.get_tree().get_nodes_in_group("statue_interact")

	if interact_zones.is_empty():
		print("No statue_interact zones found.")
		return false

	var nearest_zone = null
	var nearest_dist = INF

	for zone in interact_zones:
		var dist = player.global_position.distance_to(zone.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_zone = zone

	var placement_radius = 64.0

	if nearest_zone == null or nearest_dist > placement_radius:
		print("Not close enough to a platform to place the statue.")
		return false

	if nearest_zone.has_meta("occupied") and nearest_zone.get_meta("occupied") == true:
		print("This platform spot is already occupied.")
		return false

	var statue_path = "res://game/chapter_3/node_7/scenes/%s.tscn" % statue_name
	if not ResourceLoader.exists(statue_path):
		print("Statue scene not found: ", statue_path)
		return false

	var statue_scene = load(statue_path)
	var statue_instance = statue_scene.instantiate()

	statue_instance.global_position = nearest_zone.global_position

	statue_instance.set_meta("statue_name", statue_name)
	statue_instance.set_meta("home_zone", nearest_zone)
	statue_instance.add_to_group("placed_statue")

	player.get_tree().current_scene.add_child(statue_instance)
	nearest_zone.set_meta("occupied", true)
	nearest_zone.set_meta("placed_statue_name", statue_name)

	# Remove from dictionary inventory
	player.inventory[statue_name] -= 1
	if player.inventory[statue_name] <= 0:
		player.inventory.erase(statue_name)

	print("Placed '%s' on platform." % statue_name)
	return true


static func try_pickup_statue(player: Node2D, is_puzzle_complete: bool) -> bool:
	if is_puzzle_complete:
		print("Puzzle is complete — statues are locked.")
		return false

	var placed_statues = player.get_tree().get_nodes_in_group("placed_statue")

	var nearest_statue = null
	var nearest_dist = INF
	var pickup_radius = 64.0

	for statue in placed_statues:
		var dist = player.global_position.distance_to(statue.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_statue = statue

	if nearest_statue == null or nearest_dist > pickup_radius:
		print("No placed statue nearby to pick up.")
		return false

	var statue_name = nearest_statue.get_meta("statue_name")
	var home_zone = nearest_statue.get_meta("home_zone")

	nearest_statue.queue_free()
	home_zone.set_meta("occupied", false)
	home_zone.remove_meta("placed_statue_name")

	# Return to dictionary inventory
	if player.inventory.has(statue_name):
		player.inventory[statue_name] += 1
	else:
		player.inventory[statue_name] = 1

	print("Picked up '%s' — returned to inventory." % statue_name)
	return true
