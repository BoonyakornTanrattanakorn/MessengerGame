extends Area2D

var dialogue = load("res://game/chapter_2/node_6/dialogue/water_serpent_encounter.dialogue")

signal boss_fight_started(player: Node2D)
signal boss_fight_won(player: Node2D)

@export var _zone_shape: CollisionShape2D = get_node_or_null("BossFightZone") as CollisionShape2D
@export var _trigger_area: Area2D = get_node_or_null("BossFightTrigger") as Area2D
@export var _borders: StaticBody2D = get_node_or_null("BossFightZoneBorders") as StaticBody2D
@export var _water_serpent: Node2D
@export var _encounter_dialogue_title: String = "start"
@export var _win_dialogue_title: String = "win"
@export var _win_2_dialogue_title: String = "win_2"
@export_range(1, 20, 1) var _required_attack_sets: int = 8

var _tracked_player: Node2D = null
var _tracked_camera: Camera2D = null
var _has_started: bool = false
var _has_won: bool = false
var _is_resolving_victory: bool = false
var _completed_attack_sets: int = 0

var _saved_limit_left: int = 0
var _saved_limit_right: int = 0
var _saved_limit_top: int = 0
var _saved_limit_bottom: int = 0

var water_serpent_bgm = "res://assets/audio/water_serpent_bgm.ogg"

func _ready() -> void:
	_set_borders_enabled(false)
	if _trigger_area != null:
		_trigger_area.body_entered.connect(_on_trigger_body_entered)
		_trigger_area.area_entered.connect(_on_trigger_area_entered)
	_bind_water_serpent()


func _on_trigger_body_entered(body: Node) -> void:
	if _has_won:
		return

	var player := _get_player_from_body(body)
	if player == null:
		return
	_start_boss_fight(player)


func _on_trigger_area_entered(area: Area2D) -> void:
	if _has_won:
		return

	var player := _get_player_from_area(area)
	if player == null:
		return
	_start_boss_fight(player)


func _start_boss_fight(player: Node2D) -> void:
	if _has_started or _has_won:
		return

	var camera := _find_player_camera(player)
	if camera == null:
		return

	_has_started = true
	_tracked_player = player
	_tracked_camera = camera
	BGMManager.stop_bgm(2.0)
	await _play_serpent_intro(player)
	await _play_encounter_dialogue()
	BGMManager.play_bgm(water_serpent_bgm, 0.0, true)
	_set_borders_enabled(true)
	_save_camera_limits(camera)
	_apply_zone_limits(camera)
	ObjectiveManager.set_objective("Survive the Water Serpent!")
	if player.has_method("return_camera"):
		player.return_camera()
	await _play_serpent_dive_to_right_and_awaken()

	boss_fight_started.emit(player)
	_reset_attack_set_progress()


func _play_encounter_dialogue() -> void:
	if dialogue == null:
		return

	DialogueManager.show_dialogue_balloon(dialogue, _encounter_dialogue_title)
	await DialogueManager.dialogue_ended


func _play_serpent_intro(player: Node2D) -> void:
	_bind_water_serpent()
	if _water_serpent == null:
		return

	if _water_serpent.has_method("prepare_intro_underwater"):
		_water_serpent.prepare_intro_underwater()
		# Ensure submerged pose is applied before camera tween starts.
		await get_tree().process_frame

	if player != null and player.has_method("focus_camera_to"):
		player.focus_camera_to(_water_serpent)
		# player.focus_camera_to tweens over 0.5s in player.gd.
		await get_tree().create_timer(0.55).timeout

	if _water_serpent.has_method("play_intro_rise"):
		_water_serpent.play_intro_rise()
		if _water_serpent.has_signal("intro_rise_finished"):
			await _water_serpent.intro_rise_finished


func _play_serpent_dive_to_right_and_awaken() -> void:
	_bind_water_serpent()
	if _water_serpent == null:
		return

	if _water_serpent.has_method("play_dive_to_right_and_awaken"):
		_water_serpent.play_dive_to_right_and_awaken()
		if _water_serpent.has_signal("dive_to_right_finished"):
			await _water_serpent.dive_to_right_finished
	elif _water_serpent.has_method("awaken"):
		_water_serpent.awaken()


func _play_post_win_cutscene() -> void:
	BGMManager.stop_bgm(2.0)
	await _play_serpent_defeat_rise_at_right()
	_set_player_idle_right()
	await _focus_camera_to_serpent()
	await _play_dialogue(_win_dialogue_title)
	await _play_serpent_final_dive()
	await _play_dialogue(_win_2_dialogue_title)
	if _tracked_player != null and _tracked_player.has_method("return_camera"):
		_tracked_player.return_camera()
	_set_player_cutscene_lock(false)


func _focus_camera_to_serpent() -> void:
	_bind_water_serpent()
	if _water_serpent == null:
		return

	if _tracked_player != null and _tracked_player.has_method("focus_camera_to"):
		_tracked_player.focus_camera_to(_water_serpent)
		await get_tree().create_timer(0.55).timeout


func _play_serpent_defeat_rise_at_right() -> void:
	_bind_water_serpent()
	if _water_serpent == null:
		return

	if _water_serpent.has_method("play_defeat_rise_at_right"):
		_water_serpent.play_defeat_rise_at_right()
		if _water_serpent.has_signal("defeat_rise_finished"):
			await _water_serpent.defeat_rise_finished
		return

	if _water_serpent.has_method("play_defeat_sequence"):
		_water_serpent.play_defeat_sequence()
		if _water_serpent.has_signal("defeat_sequence_finished"):
			await _water_serpent.defeat_sequence_finished


func _play_serpent_final_dive() -> void:
	_bind_water_serpent()
	if _water_serpent == null:
		return

	if _water_serpent.has_method("play_defeat_final_dive"):
		_water_serpent.play_defeat_final_dive()
		if _water_serpent.has_signal("defeat_final_dive_finished"):
			await _water_serpent.defeat_final_dive_finished
		return

	if _water_serpent.has_method("play_defeat_sequence"):
		_water_serpent.play_defeat_sequence()
		if _water_serpent.has_signal("defeat_sequence_finished"):
			await _water_serpent.defeat_sequence_finished


func _play_dialogue(title: String) -> void:
	if dialogue == null:
		return

	DialogueManager.show_dialogue_balloon(dialogue, title)
	await DialogueManager.dialogue_ended


func _bind_water_serpent() -> void:
	if _water_serpent == null:
		_water_serpent = get_tree().current_scene.find_child("WaterSerpent", true, false) as Node2D

	if _water_serpent == null:
		return

	if _water_serpent.has_signal("boss_defeated") and not _water_serpent.is_connected("boss_defeated", Callable(self, "_on_water_serpent_defeated")):
		_water_serpent.connect("boss_defeated", Callable(self, "_on_water_serpent_defeated"))
	if _water_serpent.has_signal("defeated") and not _water_serpent.is_connected("defeated", Callable(self, "_on_water_serpent_defeated")):
		_water_serpent.connect("defeated", Callable(self, "_on_water_serpent_defeated"))
	if _water_serpent.has_signal("attack_set_completed") and not _water_serpent.is_connected("attack_set_completed", Callable(self, "_on_water_serpent_attack_set_completed")):
		_water_serpent.connect("attack_set_completed", Callable(self, "_on_water_serpent_attack_set_completed"))
	if not _water_serpent.is_connected("tree_exited", Callable(self, "_on_water_serpent_tree_exited")):
		_water_serpent.tree_exited.connect(_on_water_serpent_tree_exited)


func _reset_attack_set_progress() -> void:
	_completed_attack_sets = 0
	_bind_water_serpent()
	if _water_serpent != null and _water_serpent.has_method("reset_attack_sets"):
		_water_serpent.reset_attack_sets()


func _on_water_serpent_attack_set_completed(total_sets: int) -> void:
	_completed_attack_sets = total_sets
	if _is_resolving_victory or _has_won or not _has_started:
		return

	if _completed_attack_sets >= _required_attack_sets:
		_set_player_cutscene_lock(true)
		_is_resolving_victory = true
		call_deferred("_resolve_set_based_victory")


func _set_player_cutscene_lock(locked: bool) -> void:
	if _tracked_player == null:
		return

	if _tracked_player.has_method("set"):
		_tracked_player.set("is_in_dialogue", locked)

	if locked and _tracked_player is CharacterBody2D:
		(_tracked_player as CharacterBody2D).velocity = Vector2.ZERO


func _set_player_idle_right() -> void:
	if _tracked_player == null:
		return

	if _tracked_player.has_method("set_facing_direction"):
		_tracked_player.set_facing_direction(Vector2.RIGHT)


func _resolve_set_based_victory() -> void:
	if _has_won or not _has_started:
		_is_resolving_victory = false
		return

	await _play_post_win_cutscene()
	_finish_boss_fight_win()


func _awaken_water_serpent() -> void:
	_bind_water_serpent()
	if _water_serpent == null:
		return

	if _water_serpent.has_method("awaken"):
		_water_serpent.call_deferred("awaken")


func _on_water_serpent_defeated() -> void:
	_finish_boss_fight_win()


func _on_water_serpent_tree_exited() -> void:
	if _has_started and not _has_won:
		_finish_boss_fight_win()


func _finish_boss_fight_win() -> void:
	if _has_won:
		return

	_has_won = true
	_has_started = false
	_is_resolving_victory = false

	if _tracked_camera != null:
		_restore_camera_limits(_tracked_camera)

	_set_borders_enabled(false)
	_disable_trigger_area()

	ObjectiveManager.set_objective("Continue to town")
	boss_fight_won.emit(_tracked_player)
	_set_player_cutscene_lock(false)

	_tracked_player = null
	_tracked_camera = null


func _disable_trigger_area() -> void:
	if _trigger_area == null:
		return

	_trigger_area.set_deferred("monitoring", false)
	_trigger_area.set_deferred("monitorable", false)


func _is_player(body: Node) -> bool:
	if body == null:
		return false

	return body.is_in_group("player") or body.name == "Player"


func _get_player_from_body(body: Node) -> Node2D:
	if _is_player(body) and body is Node2D:
		return body as Node2D
	return null


func _get_player_from_area(area: Area2D) -> Node2D:
	if area == null:
		return null

	if area.is_in_group("player_hurtbox"):
		var owner := area.get_parent()
		if _is_player(owner) and owner is Node2D:
			return owner as Node2D

	if _is_player(area) and area is Node2D:
		return area as Node2D

	return null


func _find_player_camera(player: Node2D) -> Camera2D:
	if player == null:
		return null

	var local_camera := player.get_node_or_null("Camera2D")
	if local_camera is Camera2D:
		return local_camera as Camera2D

	return get_tree().root.find_child("Camera2D", true, false) as Camera2D


func _save_camera_limits(camera: Camera2D) -> void:
	_saved_limit_left = camera.limit_left
	_saved_limit_right = camera.limit_right
	_saved_limit_top = camera.limit_top
	_saved_limit_bottom = camera.limit_bottom


func _apply_zone_limits(camera: Camera2D) -> void:
	if _zone_shape == null:
		return
	if not (_zone_shape.shape is RectangleShape2D):
		return

	var zone_rect_shape := _zone_shape.shape as RectangleShape2D
	var half_size := zone_rect_shape.size * 0.5
	var center := _zone_shape.global_position

	camera.limit_left = int(floor(center.x - half_size.x))
	camera.limit_right = int(ceil(center.x + half_size.x))
	camera.limit_top = int(floor(center.y - half_size.y))
	camera.limit_bottom = int(ceil(center.y + half_size.y))


func _restore_camera_limits(camera: Camera2D) -> void:
	camera.limit_left = _saved_limit_left
	camera.limit_right = _saved_limit_right
	camera.limit_top = _saved_limit_top
	camera.limit_bottom = _saved_limit_bottom


func _set_borders_enabled(enabled: bool) -> void:
	if _borders == null:
		return

	for child in _borders.get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", not enabled)
