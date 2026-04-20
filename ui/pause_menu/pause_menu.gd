extends Control
class_name PauseMenu

signal resume_requested
signal settings_requested
signal quit_requested

@onready var resume_button: Button = %ResumeButton
@onready var settings_panel: Control = %SettingsPanel
@onready var bgm_slider: HSlider = %BGMSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var back_button: Button = %BackButton
@onready var menu_button: Button = %MenuButton

var is_settings_open: bool = false

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Initialize sliders to 100% (default/normal volume)
	bgm_slider.value = 100.0
	sfx_slider.value = 100.0

func open() -> void:
	visible = true
	if not is_settings_open:
		resume_button.grab_focus()
	else:
		back_button.grab_focus()

func close() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause_menu"):
		if is_settings_open:
			_on_back_button_pressed()
		else:
			_on_resume_button_pressed()
		get_viewport().set_input_as_handled()

func _on_resume_button_pressed() -> void:
	emit_signal("resume_requested")

func _on_settings_button_pressed() -> void:
	is_settings_open = true
	resume_button.visible = false
	%SettingsButton.visible = false
	%QuitButton.visible = false
	menu_button.visible = false
	settings_panel.visible = true
	back_button.visible = true
	back_button.grab_focus()
	emit_signal("settings_requested")

func _on_back_button_pressed() -> void:
	is_settings_open = false
	resume_button.visible = true
	%SettingsButton.visible = true
	%QuitButton.visible = true
	menu_button.visible = true
	settings_panel.visible = false
	back_button.visible = false
	resume_button.grab_focus()

func _on_quit_button_pressed() -> void:
	emit_signal("quit_requested")

func _on_bgm_slider_value_changed(value: float) -> void:
	# Convert percentage (0-200%) to dB
	# 100% = 0dB (normal volume)
	# 0% = -80dB (silent)
	# 200% = +6dB (loud)
	var volume_db: float
	if value <= 100.0:
		volume_db = -80.0 + (value / 100.0) * 80.0
	else:
		volume_db = (value - 100.0) * 0.06
	
	if BGMManager:
		var master_bus_index = AudioServer.get_bus_index("Master")
		if master_bus_index != -1:
			AudioServer.set_bus_volume_db(master_bus_index, volume_db)

func _on_sfx_slider_value_changed(value: float) -> void:
	# Convert percentage (0-200%) to dB
	# 100% = 0dB (normal volume)
	# 0% = -80dB (silent)
	# 200% = +6dB (loud)
	var volume_db: float
	if value <= 100.0:
		volume_db = -80.0 + (value / 100.0) * 80.0
	else:
		volume_db = (value - 100.0) * 0.06
	
	if AudioServer.get_bus_index("SFX") != -1:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), volume_db)


func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/menu/Main_menu.tscn")
