extends Node
class_name SkillComponent

@export var wind_scene: PackedScene
@export var fire_small_scene: PackedScene
@export var fire_heavy_scene: PackedScene
@export var water_fairy_scene: PackedScene
@export var water_wave_scene: PackedScene
@export var rock_pillar_scene: PackedScene

var scenes = {}

func _ready():
	# Scenes should be assigned in the editor; provide lightweight helpers
	scenes = {
		"wind": wind_scene,
		"fire_small": fire_small_scene,
		"fire_heavy": fire_heavy_scene,
		"water_fairy": water_fairy_scene,
		"water_wave": water_wave_scene,
		"rock_pillar": rock_pillar_scene,
	}

	_validate_scenes()


func _validate_scenes() -> void:
	# Print a concise warning for any unassigned skill scenes so designers notice in output
	for name in scenes.keys():
		if scenes[name] == null:
			print("[SkillComponent] scene not assigned:", name)


func has_scene(name: String) -> bool:
	return scenes.get(name, null) != null


func instantiate(name: String) -> Node:
	var packed = scenes.get(name, null)
	if packed == null:
		return null
	return packed.instantiate()


func _get_player():
	return get_parent()


func shoot_wind_wave() -> void:
	var player = _get_player()
	if wind_scene == null:
		return
	if player.skill_locked:
		return
	var aim_dir: Vector2 = player.last_direction
	if player.has_method("get_aim_direction"):
		aim_dir = player.get_aim_direction()
	if aim_dir.length() > 0.0:
		player.last_direction = aim_dir
	var wave = wind_scene.instantiate()
	wave.direction = aim_dir
	wave.global_position = player.global_position + player.skill_offset
	wave.rotation = aim_dir.angle()
	get_tree().current_scene.add_child(wave)


func shoot_fire_small() -> void:
	var player = _get_player()
	if fire_small_scene == null:
		return
	if player.skill_locked:
		return
	var aim_dir: Vector2 = player.last_direction
	if player.has_method("get_aim_direction"):
		aim_dir = player.get_aim_direction()
	if aim_dir.length() > 0.0:
		player.last_direction = aim_dir
	var ball = fire_small_scene.instantiate()
	ball.direction = aim_dir
	ball.global_position = player.global_position + player.skill_offset
	ball.rotation = aim_dir.angle()
	get_tree().current_scene.add_child(ball)
	if player.has_method("add_heat"):
		player.add_heat(20.0)


func shoot_fire_heavy() -> void:
	var player = _get_player()
	if fire_heavy_scene == null:
		return
	if player.skill_locked:
		return
	var aim_dir: Vector2 = player.last_direction
	if player.has_method("get_aim_direction"):
		aim_dir = player.get_aim_direction()
	if aim_dir.length() > 0.0:
		player.last_direction = aim_dir
	var ball = fire_heavy_scene.instantiate()
	ball.direction = aim_dir
	ball.global_position = player.global_position + player.skill_offset
	ball.rotation = aim_dir.angle()
	get_tree().current_scene.add_child(ball)
	if player.has_method("add_heat"):
		player.add_heat(40.0)


func summon_fairy() -> void:
	var player = _get_player()
	if player.cool_gauge + 1 > player.max_cool_gauge:
		return
	if player.skill_locked:
		return
	if player.has_method("add_cool"):
		player.add_cool(1)
	player.is_controlling_fairy = true
	player.fairy_timer = player.fairy_duration
	if water_fairy_scene != null:
		player.fairy_instance = water_fairy_scene.instantiate()
		player.fairy_instance.global_position = player.global_position + Vector2(16, 0)
		get_tree().current_scene.add_child(player.fairy_instance)
		if player.fairy_instance.has_method("activate_camera"):
			player.fairy_instance.activate_camera()
		if player.player_camera:
			player.player_camera.enabled = false
		print("[Fairy] Summoned — camera switched to fairy")


func end_fairy() -> void:
	var player = _get_player()
	player.is_controlling_fairy = false
	player.fairy_timer = 0.0
	player.fairy_cooldown_timer = player.fairy_cooldown
	if player.fairy_instance != null:
		if player.fairy_instance.has_method("deactivate_camera"):
			player.fairy_instance.deactivate_camera()
		player.fairy_instance.queue_free()
		player.fairy_instance = null
	if player.player_camera:
		player.player_camera.enabled = true
	print("[Fairy] Dismissed — camera returned to player")


func handle_fairy_movement(delta: float) -> void:
	var player = _get_player()
	if player.fairy_instance == null:
		return
	var dir = Input.get_vector("left", "right", "up", "down")
	if player.fairy_instance.has_method("move"):
		player.fairy_instance.move(dir, delta)
	if Input.is_action_just_pressed("interact") and player.fairy_instance != null:
		print("[Fairy] Interact pressed")
		if player.fairy_instance.has_method("try_interact"):
			player.fairy_instance.try_interact()


func shoot_water_wave(level: int) -> void:
	var player = _get_player()
	if player.skill_locked:
		return
	var cost = level
	if player.cool_gauge + cost > player.max_cool_gauge:
		level = player.max_cool_gauge - player.cool_gauge
		if level <= 0:
			return
		cost = level
	if player.has_method("add_cool"):
		player.add_cool(cost)
	var aim_dir: Vector2 = player.last_direction
	if player.has_method("get_aim_direction"):
		aim_dir = player.get_aim_direction()
	if aim_dir.length() > 0.0:
		player.last_direction = aim_dir
	if water_wave_scene != null:
		var wave = water_wave_scene.instantiate()
		wave.global_position = player.global_position + aim_dir * 40.0
		wave.direction = aim_dir
		wave.rotation = aim_dir.angle()
		wave.level = level
		get_tree().current_scene.add_child(wave)


func activate_earth_shield() -> void:
	var player = _get_player()
	if player.is_shield_active:
		return
	if player.skill_locked:
		return
	player.current_shield_hp = player.shield_max_hp
	player.is_shield_active = true
	print("Earth Shield Activated! HP: ", player.current_shield_hp)
	if player.animated_sprite.has_node("ShieldVisual"):
		player.animated_sprite.get_node("ShieldVisual").show()


func spawn_rock_pillar() -> void:
	var player = _get_player()
	if rock_pillar_scene == null:
		return
	if player.skill_locked:
		return
		
	player.active_pillars = player.active_pillars.filter(func(p): return is_instance_valid(p))
	
	if player.active_pillars.size() >= player.max_pillars:
		var oldest = player.active_pillars.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
			
	var pillar = rock_pillar_scene.instantiate()
	var spawn_pos = player.global_position + player.last_direction * 32.0
	pillar.global_position = spawn_pos
	
	var is_on_water = false
	if player.has_method("check_if_water_at"):
		is_on_water = player.check_if_water_at(spawn_pos)
	
	get_tree().current_scene.add_child(pillar)
	player.active_pillars.append(pillar)
	
	if pillar.has_method("setup_pillar"):
		pillar.setup_pillar(is_on_water)
