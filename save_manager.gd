extends Node

# To save node : have current scene in group "game_scene", add node to group "savable"
#                Add save_id, save_scope field and func save(), load(data) 

var save_path = "user://savegame.json"

var save_data = {
	"global": {},
	"scene": "",
	"scenes": {}
}

var init_data = {
	"global": {},
	"scene": "",
	"scenes": {}
}

var init_scene_path = "res://test scene.tscn"


func save_game():
	var scene = get_tree().current_scene
	
	if scene == null:
		return
	
	if not scene.is_in_group("game_scene"):
		return

	var current_scene = scene.scene_file_path
	save_data["scene"] = current_scene

	# Create scene entry if missing
	if not save_data["scenes"].has(current_scene):
		save_data["scenes"][current_scene] = {}

	var scene_data = save_data["scenes"][current_scene]

	var savables = get_tree().get_nodes_in_group("savable")

	for node in savables:
		if not node.has_method("save"):
			continue	
		var data = node.save()
		match node.save_scope:
			"global":
				save_data["global"][node.save_id] = data
			"scene":
				scene_data[node.save_id] = data

	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()



func load_game():

	if not FileAccess.file_exists(save_path):
		new_game()
		return

	var file = FileAccess.open(save_path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		new_game()
		return

	save_data = parsed

	var scene_path = save_data.get("scene", init_scene_path)

	# Validate scene exists
	if not ResourceLoader.exists(scene_path):
		print("Saved scene missing. Loading init scene.")
		scene_path = init_scene_path

	get_tree().change_scene_to_file(scene_path)

	await get_tree().process_frame

	restore_objects()


func restore_objects():
	await get_tree().process_frame
	var current_scene = get_tree().current_scene.scene_file_path
	var scene_data = save_data["scenes"].get(current_scene, {})

	var savables = get_tree().get_nodes_in_group("savable")

	for node in savables:
		if not node.has_method("load_data"):
			continue

		var data = {}

		if node.save_scope == "global":
			data = save_data["global"].get(node.save_id, {})
		elif node.save_scope == "scene":
			data = scene_data.get(node.save_id, {})

		# Skip if no saved data
		if data.is_empty():
			continue

		node.load_data(data)


func new_game():
	save_data = init_data.duplicate(true)
	
	get_tree().change_scene_to_file(init_scene_path)
	
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("Auto saving before exit...")
		save_game()
