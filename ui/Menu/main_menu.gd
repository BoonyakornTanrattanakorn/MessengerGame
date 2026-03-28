extends Control

func _ready():
	$CenterContainer/VBoxContainer/NewGameButton.pressed.connect(_start_game)
	$CenterContainer/VBoxContainer/LoadGameButton.pressed.connect(_load_game)
	$CenterContainer/VBoxContainer/QuitButton.pressed.connect(_quit_game)
	if not FileAccess.file_exists(SaveManager.save_path): 
		$CenterContainer/VBoxContainer/LoadGameButton.disabled = true
func _start_game():
	SaveManager.new_game()

func _load_game():
	SaveManager.load_game()

func _quit_game():
	get_tree().quit()
