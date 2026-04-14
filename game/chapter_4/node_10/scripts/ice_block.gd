extends CharacterBody2D
class_name IceBlock

@export var tile_size := 16
@export var width_in_tiles := 2
@export var height_in_tiles := 2
@export var slide_speed := 200 
@export var push_speed := 100
@export var save_id = ""
@export var save_scope = "scene"

var speed := 200
var sliding := false
var slide_direction := Vector2.ZERO
var target_position := Vector2.ZERO
var level = null

@export var level_scene_path: NodePath
var level_scene : Node2D

func _ready():
	add_to_group("savable")
	if save_id == "" :
		save_id = get_save_id()
	level_scene = get_node(level_scene_path)
	level = get_parent()
	$Area2D.area_entered.connect(_on_area_entered)

# Start sliding in a direction
func start_slide(direction: Vector2) -> bool:
	if sliding:
		return false

	# force axis-aligned movement
	slide_direction = Vector2(sign(direction.x), sign(direction.y))

	if slide_direction.x != 0:
		slide_direction.y = 0
	elif slide_direction.y != 0:
		slide_direction.x = 0

	target_position = global_position + slide_direction * tile_size

	if not can_slide_or_push(slide_direction):
		return false

	sliding = true
	return true

func _physics_process(delta):

	if is_on_ice_tile(global_position):
		speed = slide_speed
	else:
		speed = push_speed

	if sliding:
		
		velocity = slide_direction * speed

		var collisions = move_and_collide(velocity * delta)

		if velocity.length() * delta >= (target_position - global_position).length():

			global_position = target_position
			sliding = false
			velocity = Vector2.ZERO

			var next_pos = global_position + slide_direction * tile_size

			if can_slide_or_push(slide_direction) and is_on_ice_tile(next_pos):
				start_slide(slide_direction)

func can_slide_or_push(direction: Vector2) -> bool:
	var tiles_to_check = []

	if direction.x != 0:
		for y in range(height_in_tiles):
			var pos = global_position + Vector2(((width_in_tiles + 1.0)/2  if direction.x > 0 else -(width_in_tiles + 1.0)/2 ) * tile_size, (y - ((height_in_tiles + 0.0)/2) +0.5) * tile_size)
			tiles_to_check.append(pos)
	elif direction.y != 0:
		for x in range(width_in_tiles):
			var pos = global_position + Vector2((x - ((width_in_tiles+ 0.0) /2) +0.5) * tile_size, ((height_in_tiles + 1.0)/2 if direction.y > 0 else -(height_in_tiles + 1.0)/2) * tile_size)
			tiles_to_check.append(pos)

	for pos in tiles_to_check:
		var blocker = get_block_at(pos)
		if blocker:
			if blocker is IceBlock: 
				if not blocker.start_slide(direction):
					return false
			if blocker is Rock:
				return false
		if level_scene.has_node("Walls"):
			var wall_layer = level_scene.get_node("Walls")
			var cell = wall_layer.local_to_map(wall_layer.to_local(pos))
			if wall_layer.get_cell_tile_data(cell) != null:
				return false  
	return true

func get_block_at(pos: Vector2):
	for child in level.get_children():
		if child == self:
			continue
		if child is IceBlock or child is Rock:
			for x in range(child.width_in_tiles):
				for y in range(child.height_in_tiles):
					var tile_pos = child.global_position + Vector2(x * tile_size, y * tile_size)
					if tile_pos.snapped(Vector2(tile_size, tile_size)) == pos.snapped(Vector2(tile_size, tile_size)):
						return child
	return null
	
func is_on_ice_tile(pos: Vector2) -> bool:
	if not level_scene.has_node("Ice"):
		return false
		
	var ice_layer = level_scene.get_node("Ice")
	var cell = ice_layer.local_to_map(ice_layer.to_local(pos))
	return ice_layer.get_cell_tile_data(cell) != null
	
func push_from_player(player):

	var push_dir = (global_position - player.global_position)

	if abs(push_dir.x) > abs(push_dir.y):
		push_dir = Vector2(sign(push_dir.x), 0)
	else:
		push_dir = Vector2(0, sign(push_dir.y))

	start_slide(push_dir)

func _on_area_entered(area):
	if area is Fire_heavy or area is Fire_small:
		melt()
		area.queue_free()
		
func recover():
	
	sliding = false
	velocity = Vector2.ZERO
	slide_direction = Vector2.ZERO

	show()

	$CollisionShape2D.set_deferred("disabled", false)

	$Area2D.set_deferred("monitoring", true)
	$Area2D.set_deferred("monitorable", true)
	
func melt():
	hide()
	$CollisionShape2D.set_deferred("disabled", true)
	$Area2D.set_deferred("monitoring", false)
	$Area2D.set_deferred("monitorable", false)
	
func get_save_id() -> String:
	var room_name = get_parent().name
	return room_name + "/" + name

func save():
	return {
		"position": {
			"x": global_position.x,
			"y": global_position.y
		},
		"visible": visible
	}

func load_data(data) -> void:
	var pos = data.get("position", null)
	
	if pos:
		global_position = Vector2(pos["x"], pos["y"])
		
	var visible = data.get("visible", null)
	if visible != null:
		if visible == true:
			recover()
		else:
			melt()
