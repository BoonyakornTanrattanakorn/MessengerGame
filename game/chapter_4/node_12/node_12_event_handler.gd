extends LevelEventHandler

@onready var start_walk: Marker2D = $"Marker/Start Walk"
@onready var end_walk: Marker2D = $"Marker/End Walk"

func _ready() -> void:
	assert(start_walk != null)
	assert(end_walk != null)
	
func handle_intro_for_level() -> void:
	var original_input_locked = player.is_in_dialogue or player.is_camera_panning

	BGMManager.play_bgm("res://assets/audio/field_theme_1.ogg", 0.0, true)

	# Hallway walk cutscene
	await slow_walk_intro()
	await show_player_thoughts()
	await show_king_cutscene()
	var outcome = await start_player_king_dialogue()
	# Handle post-dialogue outcomes
	match outcome:
		"thanks_king":
			await normal_ending()
		"fight_begins":
			await equip_fire_power()
			await start_fight_sequence()
		"player_killed":
			await player_killed_sequence()
	# Restore player input
	player.is_in_dialogue = original_input_locked

func show_player_thoughts() -> void:
	# Simulate player thinking (can be replaced with dialogue balloon or cutscene text)
	await get_tree().create_timer(1.0).timeout

func show_king_cutscene() -> void:
	# Simulate king cutscene (can be replaced with dialogue balloon or cutscene text)
	await get_tree().create_timer(1.0).timeout

func normal_ending() -> void:
	# Placeholder for normal ending logic
	pass

func equip_fire_power() -> void:
	# Auto-equip player with fire power
	player.playerAttribute = "fire"
	if player.hud:
		player.hud.set_current_skill("fire")

func start_fight_sequence() -> void:
	# Placeholder for starting the fight
	pass

func player_killed_sequence() -> void:
	# Placeholder for player killed logic
	pass

func slow_walk_intro() -> void:
	# Move player to start
	player.global_position = start_walk.global_position

	# Save original speed, animation speed, and input state
	var original_speed = player.speed
	var anim_sprite = player.animated_sprite
	var original_anim_speed = anim_sprite.speed_scale if anim_sprite.has_method("speed_scale") else 1.0

	# Disable player input
	player.is_in_dialogue = true

	# Set slow speed and animation
	player.speed = 600.0
	if anim_sprite:
		anim_sprite.speed_scale = 0.5

	# Calculate direction and distance
	var direction = (end_walk.global_position - start_walk.global_position).normalized()
	player.set_facing_direction(direction)

	# Play walk animation manually
	if anim_sprite:
		var facing = player._facing_suffix(direction)
		var walk_anim = "walk " + facing
		if anim_sprite.animation != walk_anim:
			anim_sprite.play(walk_anim)

	# Walk to end marker
	var distance = start_walk.global_position.distance_to(end_walk.global_position)
	var duration = distance / player.speed
	var tween = create_tween()
	tween.tween_property(player, "global_position", end_walk.global_position, duration)

	# Wait for tween to finish
	await tween.finished

	# Restore speed and animation
	player.speed = original_speed
	if anim_sprite:
		anim_sprite.speed_scale = original_anim_speed
		anim_sprite.play("idle " + player._facing_suffix(direction))

func start_player_king_dialogue() -> String:
	var dialogue_resource = load("res://game/chapter_4/node_12/dialogue/intro.dialogue")
	if dialogue_resource == null:
		push_error("Dialogue resource not found! Please set the correct path.")
		return "error"

	var dialogue_manager = Engine.get_singleton("DialogueManager")
	var balloon = dialogue_manager.show_dialogue_balloon(dialogue_resource)

	# Wait for dialogue to finish and get the last branch
	var result = await balloon.finished if balloon.has_signal("finished") else await dialogue_manager.dialogue_ended
	# Try to get the last branch (title) if possible
	if typeof(result) == TYPE_STRING:
		return result
	return ""
