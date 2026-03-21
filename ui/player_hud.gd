extends CanvasLayer

const PAUSE_MENU_SCENE = preload("res://ui/pause_menu/pause_menu.tscn")

# References to current selected labels/icons
#@onready var skill_label = %SkillName
@onready var skill_icon = %SkillIcon
@onready var skill_slot = %SkillSlot
@onready var item_icon = %ItemIcon
@onready var item_count_label = %ItemCount
# Skill list — add more elements here as you implement them
var skills = [
	{"name": "Wind",  "attribute": "wind",  "color": Color(0.5, 1.0, 0.8), "icon": preload("res://assets/icons/wind.png")},
	{"name": "Fire",  "attribute": "fire",  "color": Color(1.0, 0.4, 0.2), "icon": preload("res://assets/icons/fire.png")},
	{"name": "Water", "attribute": "water", "color": Color(0.2, 0.6, 1.0), "icon": preload("res://assets/icons/water.png")},
]

# Item list — populate as needed
var items = []

var skill_index = 0
var item_index = 0
var pause_menu: PauseMenu

signal skill_changed(attribute: String)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu = PAUSE_MENU_SCENE.instantiate() as PauseMenu
	add_child(pause_menu)
	pause_menu.resume_requested.connect(_on_pause_resume_requested)
	pause_menu.settings_requested.connect(_on_pause_settings_requested)
	pause_menu.quit_requested.connect(_on_pause_quit_requested)

	update_skill_display()
	call_deferred("refresh_items") 

func _process(_delta):
	if get_tree().paused:
		return

	# Skill bar — up/down
	if Input.is_action_just_pressed("skill_up"):
		skill_index = (skill_index - 1 + skills.size()) % skills.size()
		update_skill_display()
		emit_signal("skill_changed", skills[skill_index]["attribute"])

	if Input.is_action_just_pressed("skill_down"):
		skill_index = (skill_index + 1) % skills.size()
		update_skill_display()
		emit_signal("skill_changed", skills[skill_index]["attribute"])

	# Item bar — left/right
	if items.size() > 0 and Input.is_action_just_pressed("skill_left"):
		item_index = (item_index - 1 + items.size()) % items.size()
		update_item_display()

	if items.size() > 0 and Input.is_action_just_pressed("skill_right"):
		item_index = (item_index + 1) % items.size()
		update_item_display()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		if get_tree().paused:
			_resume_game()
		else:
			_pause_game()
		get_viewport().set_input_as_handled()

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
	skill_icon.texture = skills[skill_index]["icon"]

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
