extends CanvasLayer

const PAUSE_MENU_SCENE = preload("res://ui/pause_menu/pause_menu.tscn")
const WORLD_MAP_SCENE = preload("res://features/worldmap/world_map_overlay.tscn")

# References to current selected labels/icons
#@onready var skill_label = %SkillName
@onready var skill_icon = %SkillIcon
@onready var wind_icon = $TopLeftGUI/ElementDisplay/Elements/WindIcon
@onready var fire_icon = $TopLeftGUI/ElementDisplay/Elements/FireIcon
@onready var water_icon = $TopLeftGUI/ElementDisplay/Elements/WaterIcon
@onready var earth_icon = $TopLeftGUI/ElementDisplay/Elements/EarthIcon
@onready var skill_slot = %SkillSlot
@onready var item_icon = %ItemIcon
@onready var item_count_label = %ItemCount
@onready var top_left_gui = $TopLeftGUI

# Objective UI
@onready var objective_box = $ObjectiveBox
@onready var objective_label = $ObjectiveBox/ObjectivePanel/MarginContainer/ObjectiveLabel

# Items UI
@export var red_gem: Texture2D
@export var blue_gem: Texture2D
@export var green_gem: Texture2D
@export var brave_stone: Texture2D
@export var potion: Texture2D
@export var antidote: Texture2D

#cool gauge
@onready var cool_gauge_ui = $TopLeftGUI/VBoxContainer/CoolGauge
#heat gauge
@onready var heat_gauge = $TopLeftGUI/VBoxContainer/HeatGauge
# Skill list — add more elements here as you implement them
var skills = [
	{"name": "Wind",  "attribute": "wind",  "color": Color(0.5, 1.0, 0.8), "icon": wind_icon},
	{"name": "Fire",  "attribute": "fire",  "color": Color(1.0, 0.4, 0.2), "icon": fire_icon},
	{"name": "Water", "attribute": "water", "color": Color(0.2, 0.6, 1.0), "icon": water_icon},
	{"name": "Earth", "attribute": "earth", "color": Color(0.7, 0.5, 0.3), "icon": earth_icon},
]

# Item list — populate as needed
var items = []

var skill_index = 0
var item_index = 0
var current_objective: String = ""
var current_objective_prefix: String = "Objective: "
var memorized_keywords: Array[String] = []
var memorized_keyword_order: Dictionary = {}

@export var save_id = "player_hud" 
@export var save_scope = "global" 
var pause_menu: PauseMenu
var world_map_overlay: WorldMapOverlay
var is_world_map_open: bool = false

signal skill_changed(attribute: String)

func _exit_tree() -> void:
	ObjectiveManager.unregister_hud(self)
var heat_gauge_value: float = 0.0
var cool_gauge_value: int = 0
var element_icons := {}

func _ready():
	add_to_group("savable")

	ObjectiveManager.register_hud(self)
	hide_objective()
	
	var players = get_tree().get_nodes_in_group("player")

	if players.size() == 0:
		print("No player found")
		return

	var player = players[0]
	
	if not player.is_node_ready():
		await player.ready
		
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu = PAUSE_MENU_SCENE.instantiate() as PauseMenu
	add_child(pause_menu)
	pause_menu.resume_requested.connect(_on_pause_resume_requested)
	pause_menu.settings_requested.connect(_on_pause_settings_requested)
	pause_menu.quit_requested.connect(_on_pause_quit_requested)

	world_map_overlay = WORLD_MAP_SCENE.instantiate() as WorldMapOverlay
	add_child(world_map_overlay)
	world_map_overlay.close_requested.connect(_on_world_map_close_requested)

	element_icons = {
		"wind": wind_icon,
		"fire": fire_icon,
		"water": water_icon,
		"earth": earth_icon,
	}
	_hide_all_element_icons()

	update_skill_display()
	call_deferred("refresh_items")
	call_deferred("_setup_health", player)

	skill_changed.connect(_on_skill_changed)
	
	# Heat gauge
	if heat_gauge != null:
		heat_gauge.set_max_hp(player.health_component.max_hp)
		heat_gauge.update_heat(0.0)
		heat_gauge.visible = false
		player.heat_changed.connect(heat_gauge.update_heat)
		player.heat_changed.connect(_on_heat_value_changed)
	else:
		print("ERROR: heat_gauge node not found! Check path: ", heat_gauge)

	# Cool gauge
	if cool_gauge_ui != null:
		cool_gauge_ui.set_max_hp(player.health_component.max_hp)
		cool_gauge_ui.update_cool(0)
		cool_gauge_ui.visible = false
		player.cool_changed.connect(cool_gauge_ui.update_cool)
		player.cool_changed.connect(_on_cool_value_changed)
	else:
		print("ERROR: cool_gauge_ui node not found! Check path: ", cool_gauge_ui)


func _setup_health(player):
	top_left_gui.set_max_health(player.player_max_hp)
	top_left_gui.update_health(player.player_hp)
	player.health_changed.connect(top_left_gui.update_health)
	

func _process(_delta):
	if get_tree().paused:
		return

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
	if items.size() > 0 and Input.is_action_just_pressed("item_rotate_left"):
		item_index = (item_index - 1 + items.size()) % items.size()
		update_item_display()

	if items.size() > 0 and Input.is_action_just_pressed("item_rotate_right"):
		item_index = (item_index + 1) % items.size()
		update_item_display()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("world_map"):
		if is_world_map_open:
			_close_world_map()
		elif not get_tree().paused:
			_open_world_map()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("pause_menu"):
		if is_world_map_open:
			_close_world_map()
		elif get_tree().paused:
			_resume_game()
		else:
			_pause_game()
		get_viewport().set_input_as_handled()

func _open_world_map() -> void:
	is_world_map_open = true
	get_tree().paused = true
	world_map_overlay.open()

func _close_world_map() -> void:
	is_world_map_open = false
	world_map_overlay.close()
	get_tree().paused = false

func _on_world_map_close_requested() -> void:
	if is_world_map_open:
		_close_world_map()

func _pause_game() -> void:
	get_tree().paused = true
	pause_menu.open()

func _resume_game() -> void:
	pause_menu.close()
	get_tree().paused = false

func _on_pause_resume_requested() -> void:
	_resume_game()

func _on_pause_settings_requested() -> void:
	# Placeholder until settings UI is implemented.
	print("Settings menu requested (not implemented yet).")

func _on_pause_quit_requested() -> void:
	get_tree().paused = false
	get_tree().quit()

func update_skill_display():
	#skill_label.text = skills[skill_index]["name"]
	# Change border color based on element
	var style = skill_slot.get_theme_stylebox("panel").duplicate()
	style.border_color = skills[skill_index]["color"]
	skill_slot.add_theme_stylebox_override("panel", style)

	var current_skill = skills[skill_index]
	_hide_all_element_icons()
	var attribute: String = current_skill["attribute"]
	if element_icons.has(attribute):
		var icon_node = element_icons[attribute]
		if icon_node != null:
			icon_node.visible = true

func _hide_all_element_icons() -> void:
	for icon_node in element_icons.values():
		if icon_node != null:
			icon_node.visible = false

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
		update_item_display()
		return

	item_index = clamp(item_index, 0, items.size() - 1)
	update_item_display()

func get_icon(item_name: String) -> Texture2D:
	match item_name:
		"red_gem": return red_gem
		"blue_gem": return blue_gem
		"green_gem": return green_gem
		"brave_stone": return brave_stone
		"potion": return potion
		"antidote": return antidote
	return null

# =========================
# Objective system
# =========================

func set_objective_text(new_text: String, prefix: String = "Objective: ") -> void:
	current_objective = new_text.strip_edges()
	current_objective_prefix = prefix

	if current_objective.is_empty():
		_refresh_objective_display()
		return

	_refresh_objective_display()

func clear_objective() -> void:
	current_objective = ""
	_refresh_objective_display()

func add_memorized_keyword(keyword: String, order_index: int = -1) -> void:
	var trimmed_keyword := keyword.strip_edges()
	if trimmed_keyword.is_empty():
		return

	var normalized_keyword := trimmed_keyword.to_lower()
	var existing_index := _find_memorized_keyword_index(normalized_keyword)

	if existing_index == -1:
		memorized_keywords.append(trimmed_keyword)

	if order_index >= 0:
		memorized_keyword_order[normalized_keyword] = order_index

	_sort_memorized_keywords()
	_refresh_objective_display()

func clear_memorized_keywords() -> void:
	memorized_keywords.clear()
	memorized_keyword_order.clear()
	_refresh_objective_display()

func get_objective_text() -> String:
	return current_objective

func show_objective() -> void:
	objective_box.show()

func hide_objective() -> void:
	objective_box.hide()

func _refresh_objective_display() -> void:
	var lines: Array[String] = []

	if not current_objective.is_empty():
		lines.append(current_objective_prefix + current_objective)

	if not memorized_keywords.is_empty():
		lines.append("Notes keyword: " + ", ".join(memorized_keywords))

	if lines.is_empty():
		objective_label.text = ""
		hide_objective()
		return

	objective_label.text = "\n".join(lines)
	show_objective()

func _find_memorized_keyword_index(normalized_keyword: String) -> int:
	for i in range(memorized_keywords.size()):
		if String(memorized_keywords[i]).to_lower() == normalized_keyword:
			return i
	return -1

func _sort_memorized_keywords() -> void:
	memorized_keywords.sort_custom(func(a: String, b: String) -> bool:
		var a_key := a.to_lower()
		var b_key := b.to_lower()
		var a_order := int(memorized_keyword_order.get(a_key, 2147483647))
		var b_order := int(memorized_keyword_order.get(b_key, 2147483647))
		if a_order == b_order:
			return a_key < b_key
		return a_order < b_order
	)

func save():
	return {
		"skill_index": skill_index,
		"item_index": item_index,
		"current_objective": current_objective,
		"current_objective_prefix": current_objective_prefix,
		"memorized_keywords": memorized_keywords.duplicate(),
		"memorized_keyword_order": memorized_keyword_order.duplicate()
	}
	
func load_data(data):
	skill_index = int(data.get("skill_index", skill_index))
	item_index = int(data.get("item_index", item_index))

	update_skill_display()
	refresh_items()

	current_objective_prefix = String(data.get("current_objective_prefix", "Objective: "))
	memorized_keywords.clear()
	memorized_keyword_order = {}
	var loaded_keyword_order = data.get("memorized_keyword_order", {})
	if loaded_keyword_order is Dictionary:
		for key in loaded_keyword_order.keys():
			memorized_keyword_order[String(key).to_lower()] = int(loaded_keyword_order[key])

	for keyword in data.get("memorized_keywords", []):
		var display_keyword := String(keyword).strip_edges()
		if display_keyword.is_empty():
			continue
		var normalized_keyword := display_keyword.to_lower()
		if _find_memorized_keyword_index(normalized_keyword) != -1:
			continue
		memorized_keywords.append(display_keyword)

	_sort_memorized_keywords()

	var saved_objective = String(data.get("current_objective", "")).strip_edges()
	if saved_objective.is_empty():
		current_objective = ""
		_refresh_objective_display()
	else:
		set_objective_text(saved_objective, current_objective_prefix)
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
