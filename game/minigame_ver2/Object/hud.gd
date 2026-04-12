extends CanvasLayer
@onready var gem_label = $VBoxContainer/HBoxContainer/GemLabel
@onready var gem_icon = $VBoxContainer/HBoxContainer/GemImage
@onready var hp_bar_ui = $TopLeftGUI
@onready var v_box = $VBoxContainer
@onready var charge_label = $VBoxContainer/ChargeRow/ChargeLabel  # ← add
@onready var charge_icon = $VBoxContainer/ChargeRow/ChargeImage   # ← add
@onready var charge_row = $VBoxContainer/ChargeRow                # ← add

var gems = 0

func _ready():
	v_box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	v_box.position = Vector2(20, 100)
	
	gem_icon.custom_minimum_size = Vector2(64, 64)
	gem_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gem_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	
	
	var font = load("res://assets/fonts/Bagura Font Pack v1.5/Basal.ttf")
	gem_label.add_theme_font_override("font", font)
	gem_label.add_theme_font_size_override("font_size", 36)
	
	# ← add charge font
	charge_label.add_theme_font_override("font", font)
	charge_label.add_theme_font_size_override("font_size", 36)
	charge_label.text = "x3"
	
	# ← add charge icon size
	charge_icon.custom_minimum_size = Vector2(64, 64)
	charge_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	charge_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	$VBoxContainer/HBoxContainer.alignment = BoxContainer.ALIGNMENT_CENTER
	gem_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	$VBoxContainer/ChargeRow.alignment = BoxContainer.ALIGNMENT_CENTER
	charge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	gem_label.text = "x0"
	charge_row.visible = false  # ← hidden by default, shown only in level 2
	
	gem_label.add_theme_color_override("font_color", Color.BLACK)
	charge_label.add_theme_color_override("font_color", Color.BLACK)
func update_gems(amount):
	gems += amount
	gem_label.text = "x" + str(gems)

# ← add these 2 functions
func update_charges(current: int):
	charge_label.text = "x" + str(current)

func show_charge_ui(show: bool):
	charge_row.visible = show

func update_health(value):
	hp_bar_ui.update_health(value)

func set_max_health(max_hp: int):
	hp_bar_ui.set_max_health(max_hp)

func get_gems() -> int:
	return gems
