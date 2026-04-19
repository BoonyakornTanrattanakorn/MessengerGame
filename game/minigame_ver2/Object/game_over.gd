# game_over.gd
extends CanvasLayer

@onready var overlay = $ColorRect
@onready var retry_btn = $ColorRect/VBoxContainer/RetryButton
@onready var label = $ColorRect/VBoxContainer/Label

signal retry_pressed

func _ready():
	visible = false
	
	# Font
	var font = load("res://assets/fonts/Bagura Font Pack v1.5/Light.ttf")
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 64)
	retry_btn.add_theme_font_override("font", font)
	retry_btn.add_theme_font_size_override("font_size", 36)
	
	retry_btn.pressed.connect(_on_retry_pressed)

func show_game_over():
	visible = true
	# Animate the overlay fading in
	overlay.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.5)

func _on_retry_pressed():
	emit_signal("retry_pressed")
