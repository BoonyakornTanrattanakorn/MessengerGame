extends Button

# TODO: fix this shitty code
@onready var Player_HUD = $"../"

func _pressed():
	Player_HUD._pause_game()
	Player_HUD.pause_menu._on_settings_button_pressed()
	get_tree().paused = true
