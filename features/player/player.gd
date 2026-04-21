extends CharacterBody2D
class_name Player

@onready var health_component: HealthComponent = $HealthComponent
@onready var movement_component: MovementComponent = $MovementComponent

var speed = 200.0  # speed in pixels/sec
var dash_speed = 500.0
var dash_duration = 0.15
var dash_cooldown = 0.5

var playerAttribute = "wind" # make enum
var is_boat_mode: bool = false
var boat_splash_sfx: String = "res://assets/audio/sfx/water_ball_sfx.ogg"
var boat_splash_interval: float = 1.0
var boat_splash_timer: float = 0.0

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
var fairy_duration: float = 8.0
var fairy_timer: float = 0.0
var fairy_cooldown: float = 1.0
var fairy_cooldown_timer: float = 0.0

# Water wave charging
var wave_charge_timer: float = 0.0
var is_charging_wave: bool = false



# Dash system
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var last_direction: Vector2 = Vector2.RIGHT  # Track last faced direction
var _wind_dash_shift_was_down: bool = false

var interact_with = null
var current_dialog = 0

# Ice slide
var is_sliding := false
var slide_direction := Vector2.ZERO
var skill_locked := false

# Mount system
var is_mounted = false
var current_mount = null

@onready var hud = $PlayerHUD  # or get_node path
@onready var animated_sprite = $AnimatedSprite2D
@onready var camera = $Camera2D

# Compatibility aliases for older code / analyzer
signal health_changed(value: int)
var player_hp: int = 0
var player_max_hp: int = 0
var is_invincible: bool = false
var invincible_timer: float = 0.0
var invincible_duration: float = 1.0

var respawn_position = Vector2(110, 115)
var skill_offset := Vector2(0, -12)

var inventory = {
	"red_gem": 0,
	"green_gem": 0,
	"blue_gem": 0,
	"brave_stone": 0,
	"snowstone": 0,
	"potion": 3,
	"antidote": 2,
	"desert_crystal": 0
}

var is_in_dialogue = false
var is_camera_panning: bool = false

@export var save_id = "player" 
@export var save_scope = "global" 

var player_camera: Camera2D = null
var _footstep_timer: float = 0.0
var _last_health_for_sfx: int = -1
var _death_sfx_played: bool = false

# Compatibility placeholders for legacy identifiers referenced by other files / analyzer
var _movement = null
@export var wind_scene: PackedScene
@export var fire_small_scene: PackedScene
@export var fire_heavy_scene: PackedScene
@export var water_fairy_scene: PackedScene
@export var water_wave_scene: PackedScene
@export var rock_pillar_scene: PackedScene


func _ready():
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	#ObjectiveManager.set_objective("Use wind power to flip the switch")
	add_to_group("sava	ble")
	hud.skill_changed.connect(_on_skill_changed)
	# Set starting attribute from HUD
	playerAttribute = hud.get_current_skill()
	$Hurtbox.add_to_group("player_hurtbox")
	player_camera = get_tree().root.find_child("Camera2D", true, false)
	print("Player camera: ", player_camera)

	# Initialize compatibility aliases and connect HealthComponent signals
	if health_component:
		player_max_hp = health_component.max_hp
		player_hp = health_component.hp
		_last_health_for_sfx = health_component.hp
		_last_health_for_sfx = health_component.hp
		health_component.connect("health_changed", Callable(self, "_on_health_changed"))
	
	# Register player to DeadManager
	DeadManager.register_player(self)
	
func _on_dialogue_started(_arg = null):
	is_in_dialogue = true
	is_dashing = false
	velocity = Vector2.ZERO
	_update_animation(Vector2.ZERO)

func _on_dialogue_ended(_arg = null):
	is_in_dialogue = false
	
func _on_skill_changed(attribute: String):
	playerAttribute = attribute
	print("Switched to: ", attribute)

func _is_input_locked() -> bool:
	return is_in_dialogue or is_camera_panning or DeadManager.is_dead

func _input(event: InputEvent) -> void:
	if not _is_input_locked():
		return

	if event.is_action("interact"):
		return

	if event is InputEventMouseButton:
		var mb_event := event as InputEventMouseButton
		if mb_event.button_index == MOUSE_BUTTON_LEFT:
			return

	get_viewport().set_input_as_handled()

func _physics_process(delta):
	var wind_dash_shift_down := Input.is_key_pressed(KEY_SHIFT)
	var wind_dash_just_pressed := wind_dash_shift_down and not _wind_dash_shift_was_down
	_wind_dash_shift_was_down = wind_dash_shift_down

	if _is_input_locked():
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	var direction = Input.get_vector("left", "right", "up", "down")
	if boat_splash_timer > 0.0:
		boat_splash_timer -= delta
	
	if Input.is_action_just_pressed("interact"):
		_play_sfx("player.interact")
		if is_mounted:
			if current_mount.can_dismount:
				current_mount.dismount_player()
		else:
			# 1. TRY TO USE/PLACE ITEM FROM HUD FIRST
			var item_used = hud._use_selected_item()
			
			if item_used:
				# Placement was successful!
				print("Statue placed via HUD logic.")
			else:
				# 2. IF NO ITEM WAS USED, TRY TO PICK UP A PLACED STATUE
				var picked_up = StatuePlacer.try_pickup_statue(self, StatuePuzzleChecker.is_puzzle_complete(get_tree()))
				if picked_up:
					hud.refresh_items()
				elif interact_with != null:
					# 3. IF NO PICKUP, TRY DIALOGUE/ACTIVATION
					if interact_with.has_method("activate"):
						interact_with.activate()
						interact_with = null

	# If mounted, skip all movement and just follow the cart
	if is_mounted:
		global_position = current_mount.mount_point.global_position
		return
	
	# Lock dir, skill when slide
	if(is_sliding): 
		direction = slide_direction 
	skill_locked = is_sliding
	
	# Update last direction if there's input
	if direction.length() > 0:
		last_direction = direction.normalized()

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
	
		# Cancel fairy with lesser_magic (C key)
		if Input.is_action_just_pressed("lesser_magic"):
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
	# Block skills when overheated
		if heat_gauge >= max_heat:
			pass  # skills locked — do nothing
		else:
			if Input.is_action_just_pressed("lesser_magic"):
				shoot_fire_small()
			if Input.is_action_just_pressed("greater_magic"):
				shoot_fire_heavy()
	elif playerAttribute == "wind":
		if wind_dash_just_pressed:
			_play_sfx("player.dash")
			movement_component.request_dash(self, last_direction)
		if Input.is_action_just_pressed("greater_magic"):
			shoot_wind_wave()
	elif playerAttribute == "water":
		# Light skill — summon fairy
		if Input.is_action_just_pressed("lesser_magic"):
			if is_controlling_fairy:
				end_fairy()  # cancel fairy early
			elif fairy_cooldown_timer <= 0 and cool_gauge < max_cool_gauge:
				summon_fairy()
		# Heavy skill — wave charge
		if Input.is_action_just_pressed("greater_magic"):
			is_charging_wave = true
			wave_charge_timer = 0.0
			_play_sfx("skill.water.charge")
		if Input.is_action_pressed("greater_magic") and is_charging_wave:
			wave_charge_timer += delta
			var preview_level = get_wave_level()
			hud.show_wave_charge_preview(cool_gauge + preview_level)
		if Input.is_action_just_released("greater_magic") and is_charging_wave:
			is_charging_wave = false
			shoot_water_wave(get_wave_level())
			hud.show_wave_charge_preview(-1)
	elif playerAttribute == "earth":
		if Input.is_action_just_pressed("lesser_magic"):
			activate_earth_shield()
		if Input.is_action_just_pressed("greater_magic"):
			spawn_rock_pillar()
	#check water
	var speed_multiplier = 1.0
	var is_on_water = false
	var check_pos = global_position + (direction * 10.0) 
	
	if check_if_water_at(check_pos):
		is_on_water = true
		if not is_standing_on_pillar(check_pos):
			speed_multiplier = 0.0 
	if check_if_void_at(global_position):
		if not check_if_platform_at(global_position) and not is_dashing:
			speed_multiplier = 0.0
			_handle_void_fall()
	# Movement + dash handled by movement component
	movement_component.process_movement(self, direction, speed_multiplier, delta)

	if is_boat_mode and speed_multiplier > 0.0 and direction.length() > 0.1 and boat_splash_timer <= 0.0:
		SFXManager.play_sfx(boat_splash_sfx, -5.0)
		boat_splash_timer = boat_splash_interval

	_update_animation(direction)

func _facing_suffix(dir: Vector2) -> String:
	if abs(dir.x) >= abs(dir.y):
		return "right" if dir.x > 0 else "left"
	else:
		return "front" if dir.y > 0 else "back"

func _update_animation(direction: Vector2) -> void:
	if not animated_sprite:
		return
	var facing = _facing_suffix(last_direction)
	var anim = ""

	if is_boat_mode:
		anim = _resolve_boat_animation(facing)
		if animated_sprite.animation != anim:
			animated_sprite.play(anim)
		return

	if is_dashing:
		anim = "dash"
		if not animated_sprite.sprite_frames.has_animation(anim):
			anim = "walk " + facing
	else:
		var moving = direction.length() > 0.1
		anim = ("walk " if moving else "idle ") + facing

	anim = _resolve_attribute_animation(anim)

	if animated_sprite.animation != anim:
		animated_sprite.play(anim)


func _resolve_attribute_animation(base_anim: String) -> String:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return base_anim

	var attr_anim := "%s %s" % [base_anim, playerAttribute]
	if animated_sprite.sprite_frames.has_animation(attr_anim):
		return attr_anim

	return base_anim


func _resolve_boat_animation(facing: String) -> String:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return "idle " + facing

	var boat_attr_anim := "boat %s %s" % [facing, playerAttribute]
	if animated_sprite.sprite_frames.has_animation(boat_attr_anim):
		return boat_attr_anim

	var boat_anim := "boat " + facing
	if animated_sprite.sprite_frames.has_animation(boat_anim):
		return boat_anim

	return _resolve_attribute_animation("idle " + facing)


func set_boat_mode(enabled: bool) -> void:
	is_boat_mode = enabled
	_update_animation(Vector2.ZERO)

func set_facing_direction(direction: Vector2) -> void:
	if direction.length() == 0:
		return
	last_direction = direction.normalized()
	_update_animation(last_direction)

func get_aim_direction() -> Vector2:
	var aim := get_global_mouse_position() - (global_position + skill_offset)
	if aim.length() < 4.0:
		return last_direction
	return aim.normalized()

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

	if area.has_meta("shield_consumed"):
		return

	if skill_component != null and skill_component.try_consume_projectile_with_shield(area):
		return
	
	var dmg = area.get("damage")
	health_component.take_damage(int(dmg) if dmg != null else 1)

# Player damage is handled by the HealthComponent; remove duplicate handler.

func add_item(item_name: String, amount: int = 1):
	if item_name in inventory:
		inventory[item_name] += amount
	else:
		inventory[item_name] = amount
	print("Got: ", item_name, " total: ", inventory[item_name])
	get_node("/root").find_child("PlayerHUD", true, false).refresh_items()


func remove_items_by_prefix(prefix: String) -> void:
	var items_to_remove: Array[String] = []
	for item_name in inventory.keys():
		if String(item_name).begins_with(prefix):
			items_to_remove.append(String(item_name))

	for item_name in items_to_remove:
		inventory.erase(item_name)

	get_node("/root").find_child("PlayerHUD", true, false).refresh_items()


func die_in_minecart_and_respawn(minecart_respawn_position):
	if current_mount != null:
		current_mount.reset_position()
		current_mount.dismount_player()
	is_mounted = false
	current_mount = null
	global_position = minecart_respawn_position
	health_component.hp = health_component.max_hp
	

func shoot_wind_wave():
	if skill_component:
		_play_sfx("skill.wind.cast")
		skill_component.shoot_wind_wave()

func save():
	return {
		"position" : {
			"x" : position.x,
			"y" : position.y
		},
		"playerAttribute" : playerAttribute,
		"player_max_hp" : health_component.max_hp,
		"player_hp" : health_component.hp,
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

	playerAttribute = data.get("playerAttribute", playerAttribute)
	hud.set_current_skill(playerAttribute)
	health_component.max_hp = int(data.get("player_max_hp", health_component.max_hp))
	health_component.hp = int(data.get("player_hp", health_component.hp))
	# Notify HUD and other listeners via the HealthComponent's signal
	health_component.call_deferred("emit_signal", "health_changed", health_component.hp)
	var loaded_inventory = data.get("inventory", {})
	for key in loaded_inventory:
		inventory[key] = int(loaded_inventory[key])


func _on_health_changed(new_hp: int) -> void:
	if _last_health_for_sfx == -1:
		_last_health_for_sfx = new_hp
	if new_hp < _last_health_for_sfx:
		_play_sfx("player.hit")
	if new_hp <= 0 and not _death_sfx_played:
		_death_sfx_played = true
		_play_sfx("player.death")
	elif new_hp > 0:
		_death_sfx_played = false
	_last_health_for_sfx = new_hp

	# keep aliases in sync
	player_hp = int(new_hp)
	player_max_hp = health_component.max_hp if health_component else player_max_hp
	emit_signal("health_changed", player_hp)


func focus_camera_to(target: Node2D):
	is_camera_panning = true
	camera.reparent(get_tree().current_scene) # detach from player

	var tween = create_tween()
	tween.tween_property(camera, "global_position", target.global_position, 0.5)


func return_camera():
	is_camera_panning = false
	camera.reparent(self)  # back to player
	camera.position = Vector2.ZERO  # reset offset


func shoot_fire_small():
	if skill_component:
		_play_sfx("skill.fire.small")
		skill_component.shoot_fire_small()


func shoot_fire_heavy():
	if skill_component:
		_play_sfx("skill.fire.heavy")
		skill_component.shoot_fire_heavy()


func add_heat(amount: float):
	heat_gauge = clamp(heat_gauge + amount, 0.0, max_heat)
	heat_cooldown_timer = heat_cooldown_delay
	heat_changed.emit(heat_gauge)
	if heat_gauge >= max_heat:
		print("Overheated! Skills locked until cooled!")


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
	if skill_component:
		_play_sfx("skill.water.cast")
		skill_component.summon_fairy()

func end_fairy():
	if skill_component:
		_play_sfx("skill.water.cast")
		skill_component.end_fairy()

func handle_fairy_movement(delta: float):
	if skill_component:
		skill_component.handle_fairy_movement(delta)

func shoot_water_wave(level: int):
	if skill_component:
		_play_sfx("skill.water.cast")
		skill_component.shoot_water_wave(level)


# Earth system
var earth_gauge: float = 0.0
var max_earth: float = 100.0


# Skill system (component)
@onready var skill_component = $SkillComponent
var active_pillars = []
var max_pillars = 3

func activate_earth_shield():
	if skill_component:
		_play_sfx("skill.shield.up")
		skill_component.activate_earth_shield()

func spawn_rock_pillar():
	if skill_component:
		_play_sfx("skill.earth.cast")
		skill_component.spawn_rock_pillar()

func _play_sfx(event_key: String) -> void:
	if SFXManager == null:
		return
	SFXManager.play_event(event_key)

func _update_footstep_sfx(direction: Vector2, speed_multiplier: float, delta: float, is_on_water: bool) -> void:
	var is_moving := direction.length() > 0.1 and speed_multiplier > 0.0 and not is_dashing and not is_controlling_fairy
	if not is_moving:
		_footstep_timer = 0.0
		return

	_footstep_timer -= delta
	if _footstep_timer > 0.0:
		return

	if is_on_water:
		_play_sfx("player.step_water")
	else:
		_play_sfx("player.step_grass")

	_footstep_timer = 0.30

func check_if_water_at(pos: Vector2) -> bool:
	var tilemap = get_tree().current_scene.find_child("Ground", true, false)
	
	if tilemap == null:
		#print("TileMapLayer 'Ground' not found")
		return false

	var local_pos = tilemap.to_local(pos)
	
	if tilemap == null:
		#print("No tile at", map_pos)
		return false
	else:
		var map_pos = tilemap.local_to_map(tilemap.to_local(pos))
		var tile_data
		if tilemap.get_cell_tile_data(map_pos) != null:
			tile_data = tilemap.get_cell_tile_data(map_pos)
			
		var tileset: TileSet = tilemap.tile_set
		if tileset == null:
			return false
		if tileset.get_custom_data_layer_by_name("is_water") == -1:
			return false
		
		if tile_data != null and tile_data.get_custom_data("is_water") != null:
			#print("FOUND WATER")
			return tile_data.get_custom_data("is_water")

	#print("NOT WATER")
	return false
	
func is_standing_on_pillar(pos: Vector2) -> bool:
	for pillar in active_pillars:
		if is_instance_valid(pillar):
			if pos.distance_to(pillar.global_position) < 25.0:
				return true
	return false
	
func check_if_void_at(pos: Vector2) -> bool:
	var tilemap = get_tree().current_scene.find_child("Ground", true, false)
	
	if tilemap == null:
		return false
	else:
		var map_pos = tilemap.local_to_map(tilemap.to_local(pos))
		var tile_data
		if tilemap.get_cell_tile_data(map_pos) != null:
			tile_data = tilemap.get_cell_tile_data(map_pos)
		
		var tileset: TileSet = tilemap.tile_set
		if tileset == null:
			return false
		if tileset.get_custom_data_layer_by_name("is_void") == -1:
			return false
			
		if tile_data != null and tile_data.get_custom_data("is_void") != null:
			return tile_data.get_custom_data("is_void")
			
	return false
	
func _handle_void_fall():
	is_in_dialogue = true
	velocity = Vector2.ZERO
	
	_play_sfx("player.death")
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5) # จางหายใน 0.5 วินาที
	tween.tween_callback(func(): _void_fall_event())

func _void_fall_event():	
	is_in_dialogue = true
	velocity = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
	#var current_scene_path = get_tree().current_scene.scene_file_path
	#get_tree().change_scene_to_file(current_scene_path)
	
	var level_scene_path = SaveManager.get_level_scene().scene_file_path
	get_tree().current_scene.load_level(level_scene_path, Vector2(400, 1370), Vector2i(0,1))
	
	var dialogue_resource = load("res://game/chapter_2/node_4/dialogue/dead.dialogue")
	if dialogue_resource:
		DialogueManager.show_dialogue_balloon(dialogue_resource, "fall_in_void")
		
		await DialogueManager.dialogue_ended
	
	is_in_dialogue = false

func check_if_platform_at(_pos: Vector2) -> bool:
	var overlapping_areas = $Hurtbox.get_overlapping_areas()
	
	for area in overlapping_areas:
		if area.is_in_group("platform"):
			return true
			
	return false

func can_move_in_direction(direction: Vector2) -> bool:

	if direction == Vector2.ZERO:
		return true

	if test_move(global_transform, direction * 4):

		var collision = move_and_collide(direction * 4, true)
		var collider = collision.get_collider()

		if collider.is_in_group("ice_block"):
			if collider.start_slide(direction):
				is_sliding = false
				velocity = Vector2.ZERO
		
		return false

	return true

func is_on_ice_tile() -> bool:
	var level = SaveManager.get_level_scene()
	if level == null:
		return false

	if not "ice_layer" in level:
		return false
	if level.ice_layer == null:
		return false
	return level.ice_layer.is_on_ice(global_position)
	
func respawn(at_position: Vector2) -> void:
	
	global_position = at_position

	# Restore HP
	if health_component:
		health_component.hp = health_component.max_hp
		health_component.health_changed.emit(health_component.hp)

	# Reset death SFX flag
	_death_sfx_played = false
	_last_health_for_sfx = health_component.hp

	# Reset movement state
	velocity = Vector2.ZERO
	is_dashing = false
	is_sliding = false
	skill_locked = false

	# Reset mount state
	if current_mount != null:
		current_mount.reset_position()
	current_mount = null
	is_mounted = false

	# Reset fairy system
	if is_controlling_fairy:
		end_fairy()
	fairy_timer = 0.0
	fairy_cooldown_timer = 0.0

	# Reset elemental gauges
	heat_gauge = 0.0
	heat_cooldown_timer = 0.0
	heat_changed.emit(heat_gauge)

	cool_gauge = 0
	cool_drain_timer = 0.0
	cool_drain_accum = 0.0
	cool_changed.emit(cool_gauge)

	# Reset earth pillars
	for pillar in active_pillars:
		if is_instance_valid(pillar):
			pillar.queue_free()
	active_pillars.clear()

	# Reset dash cooldown
	dash_timer = 0.0
	dash_cooldown_timer = 0.0

	# Reset animation safely
	_update_animation(Vector2.ZERO)
	
	print("Player respawned at:", at_position)
