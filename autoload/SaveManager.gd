extends Node

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

var init_scene_path = "res://chapters/chapter_1/node_2/node_2.tscn"


func save_game():
	var level_scene = get_level_scene()
	if level_scene == null:
		return

	var current_scene = level_scene.scene_file_path
	save_data["scene"] = current_scene

	if not save_data["scenes"].has(current_scene):
		save_data["scenes"][current_scene] = {}

	var scene_data = save_data["scenes"][current_scene]

	var root_scene = get_tree().current_scene

	var savables = []

	savables += root_scene.find_children("*", "", true, false)
	savables += level_scene.find_children("*", "", true, false)
	for node in get_tree().root.get_children():
		if node == root_scene:
			continue
		savables += node.find_children("*", "", true, false)
		savables.append(node)
	

	for node in savables:

		if not node.is_in_group("savable"):
			continue
			
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
	print(save_data, init_data)
	if save_data == init_data:
		new_game()
		return

	var level_path = save_data.get("scene", "")

	get_tree().change_scene_to_file(init_scene_path)
	await get_tree().scene_changed
	
	#var player = get_tree().current_scene.get_node("Player")
	#var player_hud = player.get_node("PlayerHUD")
	#player_hud._pause_game()
	
	var root_scene = get_tree().current_scene

	if level_path != "":
		root_scene.load_level(level_path, Vector2.ZERO)

	restore_objects()



func restore_objects():
	await get_tree().process_frame
	var level_scene = get_level_scene()

	if level_scene == null:
		return

	var current_scene = level_scene.scene_file_path
	
	var scene_data = save_data["scenes"].get(current_scene, {})

	var root_scene = get_tree().current_scene

	var savables = []

	savables += root_scene.find_children("*", "", true, false)
	savables += level_scene.find_children("*", "", true, false)
	for node in get_tree().root.get_children():
		if node == root_scene:
			continue
		savables += node.find_children("*", "", true, false)
		savables.append(node)
		
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

func get_level_scene():
	var root = get_tree().current_scene
	if root == null:
		return null
		
	var holder = root.get_node_or_null("LevelHolder")
	if holder == null:
		return null
		
	if holder.get_child_count() == 0:
		return null
		
	return holder.get_child(0)
	

func new_game():
	save_data = init_data.duplicate(true)
	get_tree().change_scene_to_file(init_scene_path)
	await get_tree().scene_changed
	var root = get_tree().current_scene
	#var setting = root.get_node_or_null("Player/PlayerHUD/Setting/SettingMenu")
	#if setting:
	#	setting.hide()
	
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("Auto saving before exit...")
		save_game()
