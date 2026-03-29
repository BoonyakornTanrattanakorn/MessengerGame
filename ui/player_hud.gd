extends CanvasLayer

# References to current selected labels/icons
#@onready var skill_label = %SkillName
@onready var skill_icon = %SkillIcon
@onready var element_icon = $HealthGUI/ElementDisplay/Elements/Sprite2D
@onready var skill_slot = %SkillSlot
@onready var item_icon = %ItemIcon
@onready var item_count_label = %ItemCount
@onready var health_gui = $HealthGUI
#cool gauge
@onready var cool_gauge_ui = $HealthGUI/VBoxContainer/CoolGauge
#heat gauge
@onready var heat_gauge = $HealthGUI/VBoxContainer/HeatGauge
# Skill list — add more elements here as you implement them
var skills = [
	{"name": "Wind",  "attribute": "wind",  "color": Color(0.5, 1.0, 0.8), "icon": preload("res://assets/icons/elements/wind_icon.png")},
	{"name": "Fire",  "attribute": "fire",  "color": Color(1.0, 0.4, 0.2), "icon": preload("res://assets/icons/fire.png")},
	{"name": "Water", "attribute": "water", "color": Color(0.2, 0.6, 1.0), "icon": preload("res://assets/icons/water.png")},
]

# Item list — populate as needed
var items = []

var skill_index = 0
var item_index = 0
var heat_gauge_value: float = 0.0
var cool_gauge_value: int = 0
signal skill_changed(attribute: String)

func _ready():
	var player = get_tree().root.find_child("Player", true, false)
	
	# Guard — player not found
	if player == null:
		print("ERROR: Player not found!")
		return
	
	update_skill_display()
	call_deferred("refresh_items")
	call_deferred("_setup_health", player)

	skill_changed.connect(_on_skill_changed)
	
	# Heat gauge
	if heat_gauge != null:
		heat_gauge.set_max_hp(player.player_max_hp)
		heat_gauge.update_heat(0.0)
		heat_gauge.visible = false
		player.heat_changed.connect(heat_gauge.update_heat)
	else:
		print("ERROR: heat_gauge node not found! Check path: ", heat_gauge)

	# Cool gauge
	if cool_gauge_ui != null:
		cool_gauge_ui.set_max_hp(player.player_max_hp)
		cool_gauge_ui.update_cool(0)
		cool_gauge_ui.visible = false
		player.cool_changed.connect(cool_gauge_ui.update_cool)
		player.cool_changed.connect(_on_cool_value_changed)
	else:
		print("ERROR: cool_gauge_ui node not found! Check path: ", cool_gauge_ui)


func _setup_health(player):
	health_gui.set_max_health(player.player_max_hp)
	health_gui.update_health(player.player_hp)
	player.health_changed.connect(health_gui.update_health)
	

func _process(_delta):
	# Skill bar — up/down
	if Input.is_action_just_pressed("element_rotate_left"):
		skill_index = (skill_index - 1 + skills.size()) % skills.size()
		update_skill_display()
		emit_signal("skill_changed", skills[skill_index]["attribute"])

	if Input.is_action_just_pressed("element_rotate_right"):
		skill_index = (skill_index + 1) % skills.size()
		update_skill_display()
		emit_signal("skill_changed", skills[skill_index]["attribute"])

	# Item bar — left/right
	if Input.is_action_just_pressed("item_rotate_left"):
		item_index = (item_index - 1 + items.size()) % items.size()
		update_item_display()

	if Input.is_action_just_pressed("item_rotate_right"):
		item_index = (item_index + 1) % items.size()
		update_item_display()

func update_skill_display():
	#skill_label.text = skills[skill_index]["name"]
	# Change border color based on element
	var style = skill_slot.get_theme_stylebox("panel").duplicate()
	style.border_color = skills[skill_index]["color"]
	skill_slot.add_theme_stylebox_override("panel", style)
	var current_skill = skills[skill_index]
	element_icon.texture = current_skill["icon"]

	if current_skill["attribute"] == "wind":
		element_icon.scale = Vector2.ONE
	else:
		var tex: Texture2D = current_skill["icon"]
		if tex != null and tex.get_width() > 0 and tex.get_height() > 0:
			element_icon.scale = Vector2(40.0 / tex.get_width(), 40.0 / tex.get_height())

func get_current_skill() -> String:
	return skills[skill_index]["attribute"]

func update_item_display():
	if items.size() == 0:
		item_icon.texture = null
		item_count_label.text = ""
		return
	item_icon.texture = items[item_index]["icon"]
	item_count_label.text = "x" + str(items[item_index]["count"])

func refresh_items():
	var player = get_tree().root.find_child("Player", true, false)
	if not player:
		return
	items.clear()
	for item_name in player.inventory:
		if player.inventory[item_name] > 0:
			items.append({
				"name": item_name,
				"count": player.inventory[item_name],
				"icon": get_icon(item_name)
			})
	if items.size() == 0:
		return
	if items.size() > 0:
		item_index = clamp(item_index, 0, items.size() - 1)
	update_item_display()

func get_icon(item_name: String) -> Texture2D:
	match item_name:
		"red_gem":    return preload("res://assets/icons/red_gem.png")
		"blue_gem":    return preload("res://assets/icons/blue_gem.png")
		"green_gem":    return preload("res://assets/icons/green_gem.png")
		"brave_stone": return preload("res://assets/icons/brave_stone.png")
		"potion":      return preload("res://assets/icons/potion.png")
		"antidote":    return preload("res://assets/icons/antidote.png")
	return null

func _on_heat_changed(value: float):
	heat_gauge.update_heat(value)

func _on_skill_changed(attribute: String):
	heat_gauge.visible = (attribute == "fire") or (heat_gauge_value > 0)
	cool_gauge_ui.visible = (attribute == "water") or (cool_gauge_value > 0)

func _on_heat_value_changed(value: float):
	heat_gauge_value = value
	heat_gauge.update_heat(value)
	# Auto hide when fully cooled and not on fire element
	if value <= 0.0 and skills[skill_index]["attribute"] != "fire":
		heat_gauge.visible = false

func _on_cool_value_changed(value: int):
	cool_gauge_value = value
	cool_gauge_ui.update_cool(value)
	if value <= 0 and skills[skill_index]["attribute"] != "water":
		cool_gauge_ui.visible = false

func show_wave_charge_preview(preview_value: int):
	if cool_gauge_ui == null:
		return
	if preview_value == -1:
		cool_gauge_ui.update_cool(cool_gauge_value)
		# Hide if not water element and gauge is empty
		if cool_gauge_value <= 0 and skills[skill_index]["attribute"] != "water":
			cool_gauge_ui.visible = false
	else:
		cool_gauge_ui.visible = true  # always show while charging
		cool_gauge_ui.update_cool_preview(clamp(preview_value, 0, 3))
