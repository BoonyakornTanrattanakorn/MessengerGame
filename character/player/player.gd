extends CharacterBody2D

var speed = 200.0  # speed in pixels/sec
var dash_speed = 500.0
var dash_duration = 0.15
var dash_cooldown = 0.5

var playerAttribute = "wind"

#HP system
@export var player_max_hp = 3
var player_hp = player_max_hp
var is_invincible = false
var invincible_timer = 0.0
var invincible_duration = 1.0 
signal health_changed

#Heat gauge for fire element
var heat_gauge: float = 0.0
var max_heat: float = 100.0
var heat_cooldown_timer: float = 0.0
var heat_cooldown_delay: float = 3.0   # seconds before cooling starts
var heat_drain_rate: float = 15.0      # gauge units drained per second
signal heat_changed(value: float)

# Water system
var cool_gauge: int = 0          # 0, 1, 2, or 3
var max_cool_gauge: int = 3
var cool_drain_timer: float = 0.0
var cool_drain_delay: float = 3.0
var cool_drain_rate: float = 0.5  # drains 1 unit per 0.5 sec
var cool_drain_accum: float = 0.0
signal cool_changed(value: int)

# Water fairy
var fairy_instance = null
var is_controlling_fairy: bool = false
var fairy_duration: float = 5.0
var fairy_timer: float = 0.0
var fairy_cooldown: float = 8.0
var fairy_cooldown_timer: float = 0.0

# Water wave charging
var wave_charge_timer: float = 0.0
var is_charging_wave: bool = false



# Dash system
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var last_direction: Vector2 = Vector2.RIGHT  # Track last faced direction

var interact_with = null
var current_dialog = 0

# Mount system
var is_mounted = false
var current_mount = null

@onready var hud = $PlayerHUD  # or get_node path
@onready var animated_sprite = $AnimatedSprite2D
@onready var camera = $Camera2D

var respawn_position = Vector2(110, 115)

var inventory = {
	"red_gem": 0,
	"green_gem": 0,
	"blue_gem": 0,
	"brave_stone": 0,
	"potion": 3,
	"antidote": 2,
}

var is_in_dialogue = false

@export var save_id = "player" 
@export var save_scope = "global" 

var player_camera: Camera2D = null


func _ready():
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	#ObjectiveManager.set_objective("Use wind power to flip the switch")
	add_to_group("savable")
	hud.skill_changed.connect(_on_skill_changed)
	# Set starting attribute from HUD
	playerAttribute = hud.get_current_skill()
	$Hurtbox.add_to_group("player_hurtbox")
	player_camera = get_tree().root.find_child("Camera2D", true, false)
	print("Player camera: ", player_camera)
	

func _on_dialogue_started(_arg = null):
	is_in_dialogue = true
	is_dashing = false
	velocity = Vector2.ZERO

func _on_dialogue_ended(_arg = null):
	is_in_dialogue = false
	
func _on_skill_changed(attribute: String):
	playerAttribute = attribute
	print("Switched to: ", attribute)

func _physics_process(delta):
	if is_in_dialogue:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	var direction = Input.get_vector("left", "right", "up", "down")
	
	# Mount/Dismount
	if Input.is_action_just_pressed("interact"):
		if is_mounted:
			if current_mount.can_dismount:
				current_mount.dismount_player()
		elif interact_with != null:
			print("Pressing F on: ", interact_with.name)
			if interact_with.has_method("activate"):
				interact_with.activate()
				interact_with = null
			elif interact_with.has_method("can_interact"):
				var dialogue_path = "res://dialogue/conversations/" + interact_with.name + ".dialogue"
				if ResourceLoader.exists(dialogue_path):
					DialogueManager.show_dialogue_balloon(
						load(dialogue_path),
						"_" + str(current_dialog)
					)
				else:
					print("No dialogue for: ", interact_with.name)
	
	# If mounted, skip all movement and just follow the cart
	if is_mounted:
		global_position = current_mount.mount_point.global_position
		return
	
	# Update last direction if there's input
	if direction.length() > 0:
		last_direction = direction.normalized()
	
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	
	# Handle damage taking
	if is_invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			is_invincible = false
	
	# Handle dashing
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			# End dash
			is_dashing = false
			dash_cooldown_timer = dash_cooldown
		else:
			# During dash: move in dash direction at dash speed
			velocity = last_direction * dash_speed
			move_and_slide()
			_update_animation(last_direction)
			return

	# Handle fire skill
	if heat_gauge > 0:
		if heat_cooldown_timer > 0:
			heat_cooldown_timer -= delta
		else:
			heat_gauge = max(0.0, heat_gauge - heat_drain_rate * delta)
			heat_changed.emit(heat_gauge)
	# Cool gauge global drain
	if cool_gauge > 0:
		if cool_drain_timer > 0:
			cool_drain_timer -= delta
		else:
			cool_drain_accum += delta
			if cool_drain_accum >= cool_drain_rate:
				cool_drain_accum = 0.0
				add_cool(-1)
	# Fairy duration countdown
	if is_controlling_fairy:
		fairy_timer -= delta
	
		# Cancel fairy with minor magic (C key)
		if Input.is_action_just_pressed("minor magic"):
			print("[Fairy] Cancelled by player")
			end_fairy()
			return
	
		if fairy_timer <= 0:
			print("[Fairy] Duration expired")
			end_fairy()
		else:
			handle_fairy_movement(delta)
			# Show remaining time debug
			if Engine.get_frames_drawn() % 60 == 0:  # print once per second
				print("[Fairy] Time remaining: ", snappedf(fairy_timer, 0.1), "s")
		return  # skip all player movement

	# Fairy cooldown countdown
	if fairy_cooldown_timer > 0:
		fairy_cooldown_timer -= delta
	# Handle skill
	if playerAttribute == "fire":
		if Input.is_action_just_pressed("minor magic"):
			shoot_fire_small()
		if Input.is_action_just_pressed("major magic"):
			shoot_fire_heavy()
	elif playerAttribute == "wind":
		if Input.is_action_just_pressed("minor magic") and dash_cooldown_timer <= 0 and not is_dashing:
			is_dashing = true
			dash_timer = dash_duration
			velocity = last_direction * dash_speed
		if Input.is_action_just_pressed("major magic"):
			shoot_wind_wave()
	elif playerAttribute == "water":
		# Light skill — summon fairy
		if Input.is_action_just_pressed("minor magic"):
			if is_controlling_fairy:
				end_fairy()  # cancel fairy early
			elif fairy_cooldown_timer <= 0 and cool_gauge < max_cool_gauge:
				summon_fairy()
		# Heavy skill — wave charge
		if Input.is_action_just_pressed("major magic"):
			is_charging_wave = true
			wave_charge_timer = 0.0
		if Input.is_action_pressed("major magic") and is_charging_wave:
			wave_charge_timer += delta
			var preview_level = get_wave_level()
			hud.show_wave_charge_preview(cool_gauge + preview_level)
		if Input.is_action_just_released("major magic") and is_charging_wave:
			is_charging_wave = false
			shoot_water_wave(get_wave_level())
			hud.show_wave_charge_preview(-1)
	elif playerAttribute == "earth":
		if Input.is_action_just_pressed("minor magic"):
			activate_earth_shield()
		if Input.is_action_just_pressed("major magic"):
			spawn_rock_pillar()
	#check water
	var speed_multiplier = 1.0
	
	var check_pos = global_position + (direction * 10.0) 
	
	if check_if_water_at(check_pos):
		if not is_standing_on_pillar(check_pos):
			speed_multiplier = 0.0 
	# Normal movement
	velocity = direction * speed * speed_multiplier
	move_and_slide()
	_update_animation(direction)

func _facing_suffix(dir: Vector2) -> String:
	if abs(dir.x) >= abs(dir.y):
		return "right" if dir.x > 0 else "left"
	else:
		return "front" if dir.y > 0 else "back"

func _update_animation(direction: Vector2) -> void:
	var facing = _facing_suffix(last_direction)
	var anim = ""

	if is_dashing:
		anim = "dash"
		if not animated_sprite.sprite_frames.has_animation(anim):
			anim = "walk " + facing
	else:
		var moving = direction.length() > 0.1
		anim = ("walk " if moving else "idle ") + facing

	if animated_sprite.animation != anim:
		animated_sprite.play(anim)

# Called by minecart to mount the player
func mount(minecart, mount_position):
	is_mounted = true
	current_mount = minecart
	global_position = mount_position
	interact_with = null

func _find_safe_dismount_position() -> Vector2:
	if current_mount == null:
		return global_position

	var base = current_mount.mount_point.global_position
	var offsets: Array[Vector2] = [
		Vector2(0, -24),
		Vector2(24, 0),
		Vector2(-24, 0),
		Vector2(0, 24),
		Vector2(0, -40)
	]

	if current_mount.move_direction != Vector2.ZERO:
		var side = current_mount.move_direction.orthogonal().normalized() * 24.0
		offsets.insert(0, side)
		offsets.insert(1, -side)

	for offset in offsets:
		var target = base + offset
		var motion = target - global_position
		if not test_move(global_transform, motion):
			return target

	return base + Vector2(0, -24)

# Called by minecart to dismount the player
func dismount():
	is_mounted = false
	if current_mount != null:
		global_position = _find_safe_dismount_position()
	current_mount = null

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body == self:
		return
	if body.has_method("can_interact"):
		if body.has_meta("no_interact"):
			return
		interact_with = body
		current_dialog = body.can_interact()
		print("Interactable: ", body.name)

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body == self:
		return
	if body == interact_with:
		interact_with = null

func _on_interaction_area_area_entered(area: Area2D) -> void:
	if area == self:
		return
	if area.has_method("can_interact"):
		if area.has_meta("no_interact"):
			return
		interact_with = area
		current_dialog = area.can_interact()
		print("Interactable area: ", area.name)

func _on_interaction_area_area_exited(area: Area2D) -> void:
	if area == self:
		return
	if area == interact_with:
		interact_with = null

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if not area.is_in_group("enemy_projectile"):
		return
	var dmg = area.get("damage")
	take_damage(int(dmg) if dmg != null else 1)

func take_damage(amount: int):
	if is_invincible:
		return
	# Can't take damage while mounted
	if is_mounted:
		return
	if is_shield_active:
		current_shield_hp -= amount
		print("Shield hit! Remaining HP: ", current_shield_hp)
		if current_shield_hp <= 0:
			is_shield_active = false
			print("Shield Broke!")
		return
	player_hp -= amount
	print("Player HP: ", player_hp)
	is_invincible = true
	invincible_timer = invincible_duration
	health_changed.emit(player_hp)
	if player_hp <= 0:
		player_hp = 0
		print("Player dead!")

func add_item(item_name: String, amount: int = 1):
	if item_name in inventory:
		inventory[item_name] += amount
	else:
		inventory[item_name] = amount
	print("Got: ", item_name, " total: ", inventory[item_name])
	get_node("/root").find_child("PlayerHUD", true, false).refresh_items()

func die_in_minecart_and_respawn(minecart_respawn_position):
	if current_mount != null:
		current_mount.reset_position()
		current_mount.dismount_player()
	is_mounted = false
	current_mount = null
	global_position = minecart_respawn_position
	player_hp = player_max_hp
	
#wind skill
@export var wind_scene: PackedScene = preload("res://Scenes/wind.tscn")
		
func shoot_wind_wave():
	if wind_scene:
		var wave = wind_scene.instantiate()
		wave.direction = last_direction
		wave.global_position = global_position
	
		wave.rotation = last_direction.angle()
		
		get_tree().current_scene.add_child(wave)

func save():
	return {
		"position" : {
			"x" : position.x,
			"y" : position.y
		},
		"playerAttribute" : playerAttribute,
		"player_max_hp" : player_max_hp,
		"player_hp" : player_hp,
		"inventory" : inventory,
		"respawn_position" : {
			"x" : respawn_position.x,
			"y" : respawn_position.y
		}
	}
	
func load_data(data):
	var pos = data.get("position", null)
	var re_pos = data.get("respawn_position", null)
	
	if re_pos:
		respawn_position = Vector2(re_pos["x"], re_pos["y"])

	if pos:
		position = Vector2(pos["x"], pos["y"])

	playerAttribute = hud.get_current_skill()
	player_max_hp = int(data.get("player_max_hp", player_max_hp))
	player_hp = int(data.get("player_hp", player_hp))
	call_deferred("emit_signal", "health_changed", player_hp)
	var loaded_inventory = data.get("inventory", {})

	for key in loaded_inventory:
		inventory[key] = int(loaded_inventory[key])
		
func focus_camera_to(target: Node2D):
	camera.reparent(get_tree().current_scene) # detach from player

	var tween = create_tween()
	tween.tween_property(camera, "global_position", target.global_position, 0.5)

func return_camera():
	camera.reparent(self)  # back to player
	camera.position = Vector2.ZERO  # reset offset
#fire skill
@export var fire_small_scene: PackedScene = preload("res://Scenes/fire_small.tscn")
@export var fire_heavy_scene: PackedScene = preload("res://Scenes/fire_heavy.tscn")

func shoot_fire_small():
	if fire_small_scene:
		var ball = fire_small_scene.instantiate()
		ball.direction = last_direction
		ball.global_position = global_position
		ball.rotation = last_direction.angle()
		get_tree().current_scene.add_child(ball)
	add_heat(20.0)

func shoot_fire_heavy():
	if fire_heavy_scene:
		var ball = fire_heavy_scene.instantiate()
		ball.direction = last_direction
		ball.global_position = global_position
		ball.rotation = last_direction.angle()
		get_tree().current_scene.add_child(ball)
	add_heat(40.0)

func add_heat(amount: float):
	heat_gauge = clamp(heat_gauge + amount, 0.0, max_heat)
	heat_cooldown_timer = heat_cooldown_delay   # reset cooldown window
	heat_changed.emit(heat_gauge)
	if heat_gauge >= max_heat:
		player_hp = 0
		health_changed.emit(player_hp)
		print("Overheated! Player dead!")

#water skill
@export var water_fairy_scene: PackedScene = preload("res://character/summon/WaterFairy.tscn")
@export var water_wave_scene: PackedScene = preload("res://Scenes/WaterWave.tscn")

func add_cool(amount: int):
	cool_gauge = clamp(cool_gauge + amount, 0, max_cool_gauge)
	cool_drain_timer = cool_drain_delay  # reset drain delay on any change
	cool_changed.emit(cool_gauge)

func get_wave_level() -> int:
	if wave_charge_timer >= 1.0:
		return 3
	elif wave_charge_timer >= 0.5:
		return 2
	else:
		return 1

func get_wave_cost(level: int) -> int:
	return level  # level 1 = 1 gauge, level 2 = 2, level 3 = 3

func summon_fairy():
	if cool_gauge + 1 > max_cool_gauge:
		return
	add_cool(1)
	is_controlling_fairy = true
	fairy_timer = fairy_duration
	fairy_instance = water_fairy_scene.instantiate()
	fairy_instance.global_position = global_position + Vector2(16, 0)
	get_tree().current_scene.add_child(fairy_instance)
	
	# Switch camera to fairy
	fairy_instance.activate_camera()
	# Disable player camera so fairy camera takes over
	if player_camera:
		player_camera.enabled = false
	print("[Fairy] Summoned — camera switched to fairy")

func end_fairy():
	is_controlling_fairy = false
	fairy_timer = 0.0
	fairy_cooldown_timer = fairy_cooldown
	if fairy_instance != null:
		fairy_instance.deactivate_camera()
		fairy_instance.queue_free()
		fairy_instance = null
	
	# Return camera to player
	if player_camera:
		player_camera.enabled = true
	print("[Fairy] Dismissed — camera returned to player")

func handle_fairy_movement(delta: float):
	if fairy_instance == null:
		return
	var dir = Input.get_vector("left", "right", "up", "down")
	fairy_instance.move(dir, delta)
	if Input.is_action_just_pressed("interact"):
		print("[Fairy] Interact pressed")
		fairy_instance.try_interact()

func shoot_water_wave(level: int):
	var cost = get_wave_cost(level)
	if cool_gauge + cost > max_cool_gauge:
		level = max_cool_gauge - cool_gauge
		if level <= 0:
			return
		cost = level
	add_cool(cost)
	if water_wave_scene:
		var wave = water_wave_scene.instantiate()
		# Offset spawn position forward in the direction of travel
		wave.global_position = global_position + last_direction *  40.0
		wave.direction = last_direction
		wave.rotation = last_direction.angle()
		wave.level = level
		get_tree().current_scene.add_child(wave)


# Earth system
var earth_gauge: float = 0.0
var max_earth: float = 100.0
signal earth_changed(value: float)

# Minor: Shield
@export var shield_max_hp = 2
var current_shield_hp = 0
var is_shield_active = false

# Major: Rock Pillars
@export var rock_pillar_scene: PackedScene = preload("res://Scenes/RockPillar.tscn")
var active_pillars = []
var max_pillars = 3

func activate_earth_shield():
	if is_shield_active: return
	
	current_shield_hp = shield_max_hp
	is_shield_active = true
	print("Earth Shield Activated! HP: ", current_shield_hp)
	if animated_sprite.has_node("ShieldVisual"):
		animated_sprite.get_node("ShieldVisual").show()

func spawn_rock_pillar():
	active_pillars = active_pillars.filter(func(p): return is_instance_valid(p))

	if active_pillars.size() >= max_pillars:
		var oldest = active_pillars.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

	if rock_pillar_scene:
		var pillar = rock_pillar_scene.instantiate()
		
		var spawn_pos = global_position + last_direction * 32.0
		pillar.global_position = spawn_pos
		
		var is_on_water = check_if_water_at(spawn_pos)
		
		get_tree().current_scene.add_child(pillar)
		
		active_pillars.append(pillar)
		
		if pillar.has_method("setup_pillar"):
			pillar.setup_pillar(is_on_water)

func check_if_water_at(pos: Vector2) -> bool:
	var tilemap = get_tree().current_scene.find_child("Ground", true, false)
	
	if tilemap == null:
		#print("TileMapLayer 'Ground' not found")
		return false

	var local_pos = tilemap.to_local(pos)
	var map_pos = tilemap.local_to_map(local_pos)

	var tile_data = tilemap.get_cell_tile_data(map_pos)
	
	if tile_data == null:
		#print("No tile at", map_pos)
		return false
	else:
		var is_water = tile_data.get_custom_data("is_water")

		if is_water == true:
			#print("FOUND WATER")
			return true

	#print("NOT WATER")
	return false
	
func is_standing_on_pillar(pos: Vector2) -> bool:
	for pillar in active_pillars:
		if is_instance_valid(pillar):
			if pos.distance_to(pillar.global_position) < 25.0:
				return true
	return false
