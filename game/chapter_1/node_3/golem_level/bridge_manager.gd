extends Node2D

var active_colors: Array = []
const MAX_ACTIVE = 2

@onready var red_layer = %Red_Shuffle
@onready var blue_layer = %Blue_Shuffle
@onready var green_layer = %Green_Shuffle

@onready var red_collision = %RedBridgeCollision
@onready var blue_collision = %BlueBridgeCollision
@onready var green_collision = %GreenBridgeCollision

@export var save_id = "bridge_manager"
@export var save_scope = "scene"

func _ready():
	add_to_group("savable")
	red_layer.visible = false
	blue_layer.visible = false
	green_layer.visible = false
	# Disable all collision shapes at start
	for shape in red_collision.get_children():
		shape.disabled = false
	for shape in blue_collision.get_children():
		shape.disabled = false
	for shape in green_collision.get_children():
		shape.disabled = false

func activate_color(color: String):
	if color in active_colors:
		print(color, " already active - ignoring")
		return  # ← already active, do nothing
	
	if active_colors.size() >= MAX_ACTIVE:
		var oldest = active_colors.pop_front()
		hide_color(oldest)
	
	active_colors.append(color)
	show_color(color)
	
	var boss = get_tree().root.find_child("GolemBoss", true, false)
	if boss and boss.has_method("try_damage"):
		boss.try_damage(color)
	
	print("Active bridges: ", active_colors)

func is_color_active(color: String) -> bool:
	return color in active_colors

func show_color(color: String):
	var layer = get_layer(color)
	var collision = get_collision(color)
	if layer:
		layer.visible = true
	if collision:
		for shape in collision.get_children():
			shape.disabled = true  # bridge ON = collision OFF

func hide_color(color: String):
	var layer = get_layer(color)
	var collision = get_collision(color)
	if layer:
		layer.visible = false
	if collision:
		for shape in collision.get_children():
			shape.disabled = false  # bridge OFF = collision ON

func reset_switches_of_color(color: String):
	for node in get_tree().get_nodes_in_group("switches"):
		if node.bridge_color == color:
			node.is_activated = false
			print("Reset switch: ", node.name)

func get_layer(color: String):
	match color:
		"red":   return red_layer
		"blue":  return blue_layer
		"green": return green_layer
	return null

func get_collision(color: String):
	match color:
		"red":   return red_collision
		"blue":  return blue_collision
		"green": return green_collision
	return null
	
func save():
	return {
		"active_colors": active_colors
	}
	
func load_data(data):

	active_colors = data.get("active_colors", [])

	for color in active_colors:
		show_color(color)
