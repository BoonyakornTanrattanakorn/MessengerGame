extends CharacterBody2D

func _ready() -> void:
	_apply_dead_state()


func mark_dead() -> void:
	GameState.chap4_node11_ice_ghost_dead = true
	_apply_dead_state()


func revive() -> void:
	GameState.chap4_node11_ice_ghost_dead = false
	show()
	set_process(true)
	set_physics_process(true)
	set_process_input(true)
	set_process_unhandled_input(true)
	set_process_unhandled_key_input(true)

	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null:
		collision_shape.disabled = false


func is_dead() -> bool:
	return GameState.chap4_node11_ice_ghost_dead


func _apply_dead_state() -> void:
	if not GameState.chap4_node11_ice_ghost_dead:
		return

	hide()
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)
	set_process_unhandled_key_input(false)

	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null:
		collision_shape.disabled = true
