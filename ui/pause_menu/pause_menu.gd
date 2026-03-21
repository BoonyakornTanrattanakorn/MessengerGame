extends Control
class_name PauseMenu

signal resume_requested
signal settings_requested
signal quit_requested

@onready var resume_button: Button = %ResumeButton

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func open() -> void:
	visible = true
	resume_button.grab_focus()

func close() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause_menu"):
		_on_resume_button_pressed()
		get_viewport().set_input_as_handled()

func _on_resume_button_pressed() -> void:
	emit_signal("resume_requested")

func _on_settings_button_pressed() -> void:
	# Placeholder until settings UI is implemented.
	print("Settings button clicked (not implemented yet).")
	emit_signal("settings_requested")

func _on_quit_button_pressed() -> void:
	emit_signal("quit_requested")
