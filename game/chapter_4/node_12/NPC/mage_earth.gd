extends Chapter4MageBase

func _ready() -> void:
	mage_element = "earth"
	weakness_element = "fire"
	attack_interval = 2.4
	vulnerability_duration = 1.5
	projectile_speed = 170.0
	super._ready()

func perform_attack_pattern() -> void:
	# Earth mage roots itself, then releases a staggered boulder ring.
	spawn_delayed_burst(global_position, 0.35, 8, 0.9, Color(0.55, 0.35, 0.2, 1.0))
	await get_tree().create_timer(0.65).timeout
	begin_vulnerability_window(1.5)
	finish_casting(2.2)
