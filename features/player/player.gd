extends CharacterBody2D

@onready var health_component: HealthComponent = $HealthComponent
@onready var movement_component: MovementComponent = $MovementComponent

var speed = 200.0  # speed in pixels/sec
var dash_speed = 500.0
var dash_duration = 0.15
var dash_cooldown = 0.5

var playerAttribute = "wind" # make enum

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

# Compatibility aliases for older code / analyzer
signal health_changed(value: int)
var player_hp: int = 0
var player_max_hp: int = 0
var is_invincible: bool = false
var invincible_timer: float = 0.0
var invincible_duration: float = 1.0

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
var is_camera_panning: bool = false

@export var save_id = "player" 
@export var save_scope = "global" 

var player_camera: Camera2D = null

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
	add_to_group("savable")
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
		health_component.connect("health_changed", Callable(self, "_on_health_changed"))
	

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
	return is_in_dialogue or is_camera_panning

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
	if _is_input_locked():
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
		if Input.is_action_just_pressed("lesser_magic"):
			shoot_fire_small()
		if Input.is_action_just_pressed("greater_magic"):
			shoot_fire_heavy()
	elif playerAttribute == "wind":
		if Input.is_action_just_pressed("lesser_magic"):
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
	
	var check_pos = global_position + (direction * 10.0) 
	
	if check_if_water_at(check_pos):
		if not is_standing_on_pillar(check_pos):
			speed_multiplier = 0.0 
	# Movement + dash handled by movement component
	movement_component.process_movement(self, direction, speed_multiplier, delta)
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

func set_facing_direction(direction: Vector2) -> void:
	if direction.length() == 0:
		return
	last_direction = direction.normalized()
	_update_animation(last_direction)

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
	health_component.take_damage(int(dmg) if dmg != null else 1)

# Player damage is handled by the HealthComponent; remove duplicate handler.

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
	health_component.hp = health_component.max_hp
	

func shoot_wind_wave():
	if skill_component:
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

	playerAttribute = hud.get_current_skill()
	health_component.max_hp = int(data.get("player_max_hp", health_component.max_hp))
	health_component.hp = int(data.get("player_hp", health_component.hp))
	# Notify HUD and other listeners via the HealthComponent's signal
	health_component.call_deferred("emit_signal", "health_changed", health_component.hp)
	var loaded_inventory = data.get("inventory", {})
	for key in loaded_inventory:
		inventory[key] = int(loaded_inventory[key])


func _on_health_changed(new_hp: int) -> void:
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
		skill_component.shoot_fire_small()


func shoot_fire_heavy():
	if skill_component:
		skill_component.shoot_fire_heavy()


func add_heat(amount: float):
	heat_gauge = clamp(heat_gauge + amount, 0.0, max_heat)
	heat_cooldown_timer = heat_cooldown_delay   # reset cooldown window
	heat_changed.emit(heat_gauge)
	if heat_gauge >= max_heat:
		health_component.hp = 0
		health_component.emit_signal("health_changed", health_component.hp)
		print("Overheated! Player dead!")


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
		skill_component.summon_fairy()

func end_fairy():
	if skill_component:
		skill_component.end_fairy()

func handle_fairy_movement(delta: float):
	if skill_component:
		skill_component.handle_fairy_movement(delta)

func shoot_water_wave(level: int):
	if skill_component:
		skill_component.shoot_water_wave(level)


# Earth system
var earth_gauge: float = 0.0
var max_earth: float = 100.0

# Minor: Shield
@export var shield_max_hp = 2
var current_shield_hp = 0
var is_shield_active = false


# Skill system (component)
@onready var skill_component = $SkillComponent
var active_pillars = []
var max_pillars = 3

func activate_earth_shield():
	if skill_component:
		skill_component.activate_earth_shield()

func spawn_rock_pillar():
	if skill_component:
		skill_component.spawn_rock_pillar()

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
