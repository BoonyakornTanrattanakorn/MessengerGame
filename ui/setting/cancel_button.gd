extends Button

@onready var setting_menu = $"../.."

func _pressed():
	setting_menu.visible = false
	get_tree().paused = false
