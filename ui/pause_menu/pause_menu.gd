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
var _missing_bus_warnings: Dictionary = {}

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Initialize sliders from current bus volume so UI matches runtime state.
	bgm_slider.set_value_no_signal(_get_bus_percent("BGM"))
	sfx_slider.set_value_no_signal(_get_bus_percent("SFX"))

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
	_set_bus_volume_from_percent("BGM", value)

func _on_sfx_slider_value_changed(value: float) -> void:
	_set_bus_volume_from_percent("SFX", value)

func _resolve_bus_index(bus_name: String) -> int:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1 and not _missing_bus_warnings.has(bus_name):
		_missing_bus_warnings[bus_name] = true
		push_warning("Audio bus not found: %s" % bus_name)
	return bus_index

func _set_bus_volume_from_percent(bus_name: String, value: float) -> void:
	var bus_index := _resolve_bus_index(bus_name)
	if bus_index == -1:
		return

	var clamped_percent := clampf(value, 0.0, 200.0)
	var linear_volume := clamped_percent / 100.0
	var volume_db := -80.0 if linear_volume <= 0.0 else linear_to_db(linear_volume)
	volume_db = clampf(volume_db, -80.0, 6.0)
	AudioServer.set_bus_volume_db(bus_index, volume_db)

func _get_bus_percent(bus_name: String) -> float:
	var bus_index := _resolve_bus_index(bus_name)
	if bus_index == -1:
		return 100.0

	var volume_db := AudioServer.get_bus_volume_db(bus_index)
	if volume_db <= -80.0:
		return 0.0

	var linear_volume := db_to_linear(volume_db)
	return clampf(linear_volume * 100.0, 0.0, 200.0)


func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/menu/main_menu.tscn")
