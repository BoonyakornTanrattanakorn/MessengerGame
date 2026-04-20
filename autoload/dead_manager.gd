extends Node

var death_scene = preload("res://ui/dead_menu/dead_scene.tscn")

var player: Player = null
var is_dead = false

func register_player(p):
	player = p


func kill_player(reason: String, respawn_position: Vector2):
	if player:
		player.hide()
		player.set_physics_process(false)
		is_dead = true
	
	get_tree().paused = true
	show_death_screen(reason, respawn_position)


func show_death_screen(reason: String, respawn_position: Vector2 = Vector2.ZERO):
	var death_ui = death_scene.instantiate()
	death_ui.process_mode = PROCESS_MODE_ALWAYS
	get_tree().current_scene.add_child(death_ui)

	death_ui.setup(reason, respawn_position)


func respawn_player():
	get_tree().paused = false
	_remove_all_spells()
	is_dead = false
	if player:
		player.show()
		player.set_physics_process(true)
		player.health_component.heal(player.health_component.max_hp)
		player.health_component.call_deferred("emit_signal", "health_changed", player.health_component.hp)
		
func _remove_all_spells():
	for spell in get_tree().get_nodes_in_group("spell"):
		if is_instance_valid(spell):
			spell.queue_free()
			