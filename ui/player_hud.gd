extends CanvasLayer

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
var items = [
	{"name": "Potion",          "count": 3, "icon": preload("res://assets/icons/potion.png")},
	{"name": "Antidote",        "count": 2, "icon": preload("res://assets/icons/antidote.png")},
]

var skill_index = 0
var item_index = 0

@export var save_id = "player_hud" 
@export var save_scope = "global" 

signal skill_changed(attribute: String)

func _ready():
	add_to_group("savable")
	update_skill_display()
	update_item_display()

func _process(_delta):
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
	if Input.is_action_just_pressed("skill_left"):
		item_index = (item_index - 1 + items.size()) % items.size()
		update_item_display()

	if Input.is_action_just_pressed("skill_right"):
		item_index = (item_index + 1) % items.size()
		update_item_display()

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
	item_icon.texture = items[item_index]["icon"]
	item_count_label.text = "x" + str(items[item_index]["count"])

func save():
	var item_counts = []
	for item in items:
		item_counts.append(item["count"])

	return {
		"skill_index": skill_index,
		"item_index": item_index,
		"item_counts": item_counts
	}
	
func load_data(data):

	skill_index = int(data.get("skill_index", skill_index))
	item_index = int(data.get("item_index", item_index))

	var counts = data.get("item_counts", [])

	for i in range(min(counts.size(), items.size())):
		items[i]["count"] = int(counts[i])

	update_skill_display()
	update_item_display()
