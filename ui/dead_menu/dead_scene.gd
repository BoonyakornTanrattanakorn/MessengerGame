extends CanvasLayer

@onready var reason_label = %DeadReason
@onready var tips_label = %Tips
@onready var respawn_button = %RespawnButton
@onready var menu_button = %MenuButton

var respawn_position: Vector2
var should_reload_game_on_respawn: bool = true

func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	respawn_button.pressed.connect(_on_respawn_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)
	
func setup(reason: String, tips: String, position: Vector2, reload_game_on_respawn: bool = true):
	reason_label.text = "Reason :  " + reason
	if tips != "":
		tips_label.text = "Tips :  " + tips
	respawn_position = position
	should_reload_game_on_respawn = reload_game_on_respawn


func _on_respawn_button_pressed():
	await SaveManager.restore_global_objects()
	await SaveManager.restore_objects()
	DeadManager.respawn_player(respawn_position)
	queue_free()
	
func _on_menu_button_pressed():
	await SaveManager.restore_global_objects()
	await SaveManager.restore_objects()
	DeadManager.respawn_player(respawn_position)
	queue_free()
	get_tree().change_scene_to_file("res://ui/menu/main_menu.tscn")
	
