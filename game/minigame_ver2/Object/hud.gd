extends CanvasLayer
@onready var gem_label = $VBoxContainer/HBoxContainer/GemLabel
@onready var gem_icon = $VBoxContainer/HBoxContainer/GemImage
@onready var hp_bar_ui = $TopLeftGUI
@onready var v_box = $VBoxContainer
@onready var charge_label = $VBoxContainer/ChargeRow/ChargeLabel  # ← add
@onready var charge_icon = $VBoxContainer/ChargeRow/ChargeImage   # ← add
@onready var charge_row = $VBoxContainer/ChargeRow                # ← add

@onready var shard_label = $VBoxContainer/ShardRow/ShardLabel
@onready var shard_icon = $VBoxContainer/ShardRow/ShardImage
@onready var shard_row = $VBoxContainer/ShardRow

var gems = 0

func _ready():
	# 1. Container & Layout Setup
	v_box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	v_box.position = Vector2(20, 100)
	
	$VBoxContainer/HBoxContainer.alignment = BoxContainer.ALIGNMENT_CENTER
	$VBoxContainer/ChargeRow.alignment = BoxContainer.ALIGNMENT_CENTER
	$VBoxContainer/ShardRow.alignment = BoxContainer.ALIGNMENT_CENTER

	# 2. Resources (Fonts)
	var font = load("res://assets/fonts/Bagura Font Pack v1.5/Basal.ttf")
	var font_size = 36
	var font_color = Color.BLACK

	# 3. Gem UI Element
	gem_icon.custom_minimum_size = Vector2(64, 64)
	gem_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gem_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	gem_label.text = "x0"
	gem_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gem_label.add_theme_font_override("font", font)
	gem_label.add_theme_font_size_override("font_size", font_size)
	gem_label.add_theme_color_override("font_color", font_color)

	# 4. Charge UI Element (Hidden by default)
	charge_icon.custom_minimum_size = Vector2(64, 64)
	charge_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	charge_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	charge_label.text = "x3"
	charge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	charge_label.add_theme_font_override("font", font)
	charge_label.add_theme_font_size_override("font_size", font_size)
	charge_label.add_theme_color_override("font_color", font_color)
	
	charge_row.visible = false 

	# 5. Shard UI Element (Hidden by default)
	shard_icon.custom_minimum_size = Vector2(64, 32)
	shard_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shard_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	shard_label.text = "x0"
	shard_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shard_label.add_theme_font_override("font", font)
	shard_label.add_theme_font_size_override("font_size", font_size)
	shard_label.add_theme_color_override("font_color", font_color)
	
	shard_row.visible = false
func update_gems(amount):
	gems += amount
	gem_label.text = "x" + str(gems)

func set_label_color(color: Color):
	gem_label.add_theme_color_override("font_color", color)
	charge_label.add_theme_color_override("font_color", color)
	shard_label.add_theme_color_override("font_color", color)
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

func update_shards(amount: int):
	shard_label.text = "x" + str(amount)

func show_shard_ui(show: bool):
	shard_row.visible = show

func show_gem_ui(show: bool):
	$VBoxContainer/HBoxContainer.visible = show  # hide gem row in main3
