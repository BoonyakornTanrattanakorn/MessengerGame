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

var is_settings_open: bool = false

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Initialize sliders with current values from audio buses
	var master_bus_index = AudioServer.get_bus_index("Master")
	if master_bus_index != -1:
		bgm_slider.value = AudioServer.get_bus_volume_db(master_bus_index)
	
	var sfx_bus_index = AudioServer.get_bus_index("SFX")
	if sfx_bus_index != -1:
		sfx_slider.value = AudioServer.get_bus_volume_db(sfx_bus_index)
	else:
		sfx_slider.value = 0.0

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
	settings_panel.visible = true
	back_button.grab_focus()
	emit_signal("settings_requested")

func _on_back_button_pressed() -> void:
	is_settings_open = false
	resume_button.visible = true
	%SettingsButton.visible = true
	%QuitButton.visible = true
	settings_panel.visible = false
	resume_button.grab_focus()

func _on_quit_button_pressed() -> void:
	emit_signal("quit_requested")

func _on_bgm_slider_value_changed(value: float) -> void:
	# Set BGM volume on the Master bus
	if BGMManager:
		BGMManager.set_volume(value)

func _on_sfx_slider_value_changed(value: float) -> void:
	# Set SFX volume - placeholder for future SFX manager
	# When SFXManager is implemented, use:
	# SFXManager.set_volume(value)
	if AudioServer.get_bus_index("SFX") != -1:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), value)
