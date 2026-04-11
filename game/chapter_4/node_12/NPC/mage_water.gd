extends Chapter4MageBase

func _ready() -> void:
	mage_element = "water"
	weakness_element = "wind"
	attack_interval = 2.5
	vulnerability_duration = 1.35
	projectile_speed = 210.0
	super._ready()

func perform_attack_pattern() -> void:
	# Water mage does delayed aimed shots to let the player dodge and counter.
	for i in range(3):
		await get_tree().create_timer(0.16).timeout
		var dir := get_direction_to_player().rotated(randf_range(-0.12, 0.12))
		spawn_projectile(dir, 0.9, 1.7, 8.0, Color(0.3, 0.65, 1.0, 1.0))

	await get_tree().create_timer(0.4).timeout
	begin_vulnerability_window(1.35)
	finish_casting(2.3)
