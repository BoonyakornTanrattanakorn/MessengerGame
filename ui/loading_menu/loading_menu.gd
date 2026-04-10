extends Control

@onready var progress_bar: ProgressBar = $ProgressBar

var levels = [
	"res://game/chapter_1/node_2/scenes/Node_2.tscn",
	"res://game/chapter_1/node_3/level_0.tscn",
	"res://game/chapter_1/node_3/level_1.tscn",
	"res://game/chapter_1/node_3/level_2.tscn",
	"res://game/chapter_1/node_3/level_3.tscn",
	"res://game/chapter_2/node_4/chapter_2_village.tscn",
	"res://game/chapter_2/node_6/scenes/chapter2_node3.tscn",
    "res://game/chapter_3/node_7/node_3_level.tscn"
]

var loaded_count := 0
var total_levels := 0

func _ready():
	total_levels = levels.size()
	preload_levels()


func preload_levels() -> void:
	for level_path in levels:
		ResourceLoader.load_threaded_request(level_path)

		var status := ResourceLoader.load_threaded_get_status(level_path)
		while status != ResourceLoader.THREAD_LOAD_LOADED:
			await get_tree().process_frame
			status = ResourceLoader.load_threaded_get_status(level_path)

		var packed_scene: PackedScene = ResourceLoader.load_threaded_get(level_path)
		if packed_scene == null:
			push_error("Failed to preload: %s" % level_path)
			continue

		SceneCache.scenes[level_path] = packed_scene

		loaded_count += 1
		progress_bar.value = float(loaded_count) / total_levels * 100

	get_tree().change_scene_to_file("res://ui/menu/main_menu.tscn")
