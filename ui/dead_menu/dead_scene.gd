extends CanvasLayer

@onready var reason_label = %DeadReason
@onready var respawn_button = %RespawnButton
@onready var menu_button = %MenuButton

var respawn_position: Vector2

func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	respawn_button.pressed.connect(_on_respawn_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)
	
func setup(reason: String, position: Vector2):
	reason_label.text = "Reason :  " + reason
	respawn_position = position


func _on_respawn_button_pressed():
	DeadManager.respawn_player(respawn_position)
	SaveManager.load_game()
	queue_free()
	
func _on_menu_button_pressed():
	DeadManager.respawn_player(respawn_position)
	queue_free()
	get_tree().change_scene_to_file("res://ui/menu/Main_menu.tscn")
	
