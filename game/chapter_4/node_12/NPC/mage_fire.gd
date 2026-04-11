extends Chapter4MageBase

func _ready() -> void:
	mage_element = "fire"
	weakness_element = "water"
	attack_interval = 2.0
	vulnerability_duration = 1.25
	projectile_speed = 240.0
	super._ready()

func perform_attack_pattern() -> void:
	# Fire mage throws two aimed fans toward the player.
	var base_dir := get_direction_to_player()
	for offset in [-0.35, 0.0, 0.35]:
		spawn_projectile(base_dir.rotated(offset), 1.0, 1.6, 8.0, Color(1.0, 0.45, 0.2, 1.0))
	await get_tree().create_timer(0.28).timeout
	base_dir = get_direction_to_player()
	for offset in [-0.22, 0.0, 0.22]:
		spawn_projectile(base_dir.rotated(offset), 1.05, 1.4, 7.0, Color(1.0, 0.3, 0.1, 1.0))
	begin_vulnerability_window(1.25)
	finish_casting(2.1)
