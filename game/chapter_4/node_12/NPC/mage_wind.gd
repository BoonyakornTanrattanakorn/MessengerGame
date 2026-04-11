extends Chapter4MageBase

func _ready() -> void:
	mage_element = "wind"
	weakness_element = "earth"
	attack_interval = 1.8
	vulnerability_duration = 1.0
	projectile_speed = 260.0
	super._ready()

func perform_attack_pattern() -> void:
	# Wind mage fires a quick aimed burst with slight drift.
	var dir := get_direction_to_player()
	for offset in [-0.22, -0.08, 0.08, 0.22]:
		spawn_projectile(dir.rotated(offset), 1.2, 1.4, 7.0, Color(0.65, 0.9, 1.0, 1.0))
		await get_tree().create_timer(0.08).timeout
	await get_tree().create_timer(0.35).timeout
	begin_vulnerability_window(1.0)
	finish_casting(1.7)
