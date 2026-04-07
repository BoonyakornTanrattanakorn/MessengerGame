extends Node

var scenes = {}

func store(scene_path: String) -> void:

	if scenes.has(scene_path):
		return

	var packed_scene: PackedScene = load(scene_path)

	if packed_scene == null:
		return

	# Instantiate temporarily to finalize dependencies (TileMap / TileSet / textures)
	var instance: Node = packed_scene.instantiate()
	add_child(instance)

	await get_tree().physics_frame

	instance.queue_free()

	scenes[scene_path] = packed_scene

func get_scene(scene_path):
	return scenes.get(scene_path)
