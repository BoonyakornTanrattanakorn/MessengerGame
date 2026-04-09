extends LevelEventHandler

@onready var start_walk: Marker2D = $"Marker/Start Walk"
@onready var end_walk: Marker2D = $"Marker/End Walk"

func _ready() -> void:
	assert(start_walk != null)
	assert(end_walk != null)
	
func handle_intro_for_level() -> void:
	BGMManager.play_bgm("res://assets/audio/field_theme_1.ogg", 0.0, true)
	await slow_walk_intro()
	# Add dialogue or other intro steps here if needed

func slow_walk_intro() -> void:
	# Move player to start
	player.global_position = start_walk.global_position

	# Save original speed, animation speed, and input state
	var original_speed = player.speed
	var anim_sprite = player.animated_sprite
	var original_anim_speed = anim_sprite.speed_scale if anim_sprite.has_method("speed_scale") else 1.0
	var original_input_locked = player.is_in_dialogue or player.is_camera_panning

	# Disable player input
	player.is_in_dialogue = true

	# Set slow speed and animation
	player.speed = 60.0
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

	# Restore player input
	player.is_in_dialogue = original_input_locked
