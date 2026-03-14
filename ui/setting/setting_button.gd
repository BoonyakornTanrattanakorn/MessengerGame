extends Button

@onready var settings_menu = $"../SettingMenu"

func _pressed():
	settings_menu.visible = true
	get_tree().paused = true
