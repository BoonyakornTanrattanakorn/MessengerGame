extends CanvasLayer

func _ready():
	$Panel/CloseButton.pressed.connect(_cancel)
	$Panel/MainMenuButton.pressed.connect(_main_menu)
	$Panel/SaveButton.pressed.connect(_save_game)
	
func _cancel():
	visible = false
	get_tree().paused = false
	
func _save_game():
	SaveManager.save_game()

func _main_menu():
	get_tree().paused = false
	SaveManager.save_game()
	get_tree().change_scene_to_file("res://ui/menu/Main_menu.tscn")
	
	
