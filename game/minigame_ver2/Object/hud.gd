extends CanvasLayer

@onready var gem_label = $VBoxContainer/HBoxContainer/GemLabel
@onready var gem_icon = $VBoxContainer/HBoxContainer/GemImage
@onready var hp_bar_ui = $TopLeftGUI
@onready var v_box = $VBoxContainer

var gems = 0

func _ready():
	# Position the whole UI top-left
	v_box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	v_box.position = Vector2(20, 100)
	
	# Gem icon size
	gem_icon.custom_minimum_size = Vector2(64, 64)
	gem_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gem_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	# Font
	var font = load("res://assets/fonts/Bagura Font Pack v1.5/Basal.ttf")
	gem_label.add_theme_font_override("font", font)
	gem_label.add_theme_font_size_override("font_size", 36)
	
	# Align label vertically centered with icon
	$VBoxContainer/HBoxContainer.alignment = BoxContainer.ALIGNMENT_CENTER
	gem_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Initial gem text
	gem_label.text = "x0"

func update_gems(amount):
	gems += amount
	gem_label.text = "x" + str(gems)

func update_health(value):
	hp_bar_ui.update_health(value)

func set_max_health(max_hp: int):
	hp_bar_ui.set_max_health(max_hp)
