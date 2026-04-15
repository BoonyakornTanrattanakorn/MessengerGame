extends LevelEventHandler

signal hallway_thoughts_finished

const INTRO_DIALOGUE := preload("res://game/chapter_4/node_12/dialogue/intro.dialogue")
const FINALE_DIALOGUE := preload("res://game/chapter_4/node_12/dialogue/finale.dialogue")

@onready var start_walk: Marker2D = $"Marker/Start Walk"
@onready var end_walk: Marker2D = $"Marker/End Walk"
@onready var king: CharacterBody2D = $"NPC/King"
@onready var soldier_center: CharacterBody2D = $"NPC/Soldier4"
@onready var mage_root: Node2D = $"Mage"

@export_group("Debug")
@export var debug_skip_mage_fight: bool = false
@export_group("Cutscene Fast Forward")
@export var hold_ctrl_walk_speed_multiplier: float = 2.5
@export var hold_ctrl_dialogue_speed_multiplier: float = 10.0

var _intro_outcome: String = ""
var _waiting_for_hallway_thoughts: bool = false
var _hallway_thoughts_done: bool = false
var _fast_forward_enabled: bool = false
var _fast_forward_balloons: Array[Node] = []
var _accusation_branch_unlocked: bool = true

func _ready() -> void:
	assert(start_walk != null)
	assert(end_walk != null)
	_set_mage_group_visible(false)
	_set_mage_ai_active(false)
	
func handle_intro_for_level() -> void:
	var original_input_locked = player.is_in_dialogue
	var original_camera_pan = player.is_camera_panning
	var original_input_locked = player.is_in_dialogue
	var original_camera_pan = player.is_camera_panning

	BGMManager.play_bgm("res://assets/audio/field_theme_1.ogg", 0.0, true)
	player.is_in_dialogue = true
	player.is_camera_panning = true
	_accusation_branch_unlocked = _resolve_accusation_branch_unlock()
	_fast_forward_enabled = true
	_track_fast_forward_loop()

	show_player_thoughts()
	await slow_walk_intro()
	if _waiting_for_hallway_thoughts and not _hallway_thoughts_done:
		await hallway_thoughts_finished
	await show_king_cutscene()
	var outcome = await start_player_king_dialogue()

	match outcome:
		"thanks_king":
			await normal_ending()
		"fight_begins":
			if _can_start_accusation_branch():
				await start_fight_sequence()
				await start_post_fight_cutscene()
			else:
				push_warning("Blocked fight branch because accusation branch is not unlocked.")
				await normal_ending()

	_fast_forward_enabled = false
	_fast_forward_balloons.clear()
	player.is_in_dialogue = original_input_locked
	player.is_camera_panning = original_camera_pan

func show_player_thoughts() -> void:
	if INTRO_DIALOGUE == null:
		_hallway_thoughts_done = true
		_waiting_for_hallway_thoughts = false
		return
	_hallway_thoughts_done = false
	_waiting_for_hallway_thoughts = true
	if not DialogueManager.dialogue_ended.is_connected(_on_hallway_thoughts_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_hallway_thoughts_dialogue_ended)
	var balloon := DialogueManager.show_dialogue_balloon(INTRO_DIALOGUE, "hallway_thoughts", [self])
	_register_fast_forward_balloon(balloon)

func _on_hallway_thoughts_dialogue_ended(resource: DialogueResource) -> void:
	if not _waiting_for_hallway_thoughts:
		return
	if resource != INTRO_DIALOGUE:
		return
	_waiting_for_hallway_thoughts = false
	_hallway_thoughts_done = true
	if DialogueManager.dialogue_ended.is_connected(_on_hallway_thoughts_dialogue_ended):
		DialogueManager.dialogue_ended.disconnect(_on_hallway_thoughts_dialogue_ended)
	hallway_thoughts_finished.emit()
	if INTRO_DIALOGUE == null:
		_hallway_thoughts_done = true
		_waiting_for_hallway_thoughts = false
		return
	_hallway_thoughts_done = false
	_waiting_for_hallway_thoughts = true
	if not DialogueManager.dialogue_ended.is_connected(_on_hallway_thoughts_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_hallway_thoughts_dialogue_ended)
	var balloon := DialogueManager.show_dialogue_balloon(INTRO_DIALOGUE, "hallway_thoughts", [self])
	_register_fast_forward_balloon(balloon)

func _on_hallway_thoughts_dialogue_ended(resource: DialogueResource) -> void:
	if not _waiting_for_hallway_thoughts:
		return
	if resource != INTRO_DIALOGUE:
		return
	_waiting_for_hallway_thoughts = false
	_hallway_thoughts_done = true
	if DialogueManager.dialogue_ended.is_connected(_on_hallway_thoughts_dialogue_ended):
		DialogueManager.dialogue_ended.disconnect(_on_hallway_thoughts_dialogue_ended)
	hallway_thoughts_finished.emit()

func show_king_cutscene() -> void:
	if king != null and king.has_node("AnimatedSprite2D"):
		var sprite: AnimatedSprite2D = king.get_node("AnimatedSprite2D")
		sprite.play("idle")
	await get_tree().create_timer(0.4).timeout

func normal_ending() -> void:
	await _escort_player_by_soldier()
	await _show_ending_banner(
		"Normal Ending\n\nThe messenger leaves the throne room in silence.\nThe monsters retreat for now, but the cycle will return."
	)

func equip_fire_power() -> void:
	player.playerAttribute = "fire"
	if player.hud:
		player.hud.set_current_skill("fire")

func start_fight_sequence() -> void:
	_set_mage_group_visible(true)

	if debug_skip_mage_fight:
		_force_clear_mages()
		await get_tree().create_timer(0.25).timeout
		return

	_set_mage_ai_active(true)
	player.is_in_dialogue = false
	player.is_camera_panning = false
	await _wait_until_all_mages_defeated()
	player.is_in_dialogue = true
	player.is_camera_panning = true
	_set_mage_ai_active(false)

func player_killed_sequence() -> void:
	await _show_ending_banner("Bad Ending\n\nThe messenger falls before changing the kingdom's fate.")

func slow_walk_intro() -> void:
	player.global_position = start_walk.global_position

	var original_speed = player.speed
	var anim_sprite = player.animated_sprite
	var original_anim_speed = anim_sprite.speed_scale if anim_sprite != null else 1.0

	player.is_in_dialogue = true

	player.speed = 70.0
	if anim_sprite:
		anim_sprite.speed_scale = 0.75

	var direction = (end_walk.global_position - start_walk.global_position).normalized()
	player.set_facing_direction(direction)
	var facing = player._facing_suffix(direction)
	var walk_anim = "walk " + facing

	if anim_sprite:
		if anim_sprite.animation != walk_anim:
			anim_sprite.play(walk_anim)

	var distance = player.global_position.distance_to(end_walk.global_position)
	var duration = distance / maxf(1.0, player.speed)
	var tween := create_tween()
	tween.tween_property(player, "global_position", end_walk.global_position, duration)

	while tween.is_running():
		var speed_multiplier := hold_ctrl_walk_speed_multiplier if _is_fast_forward_pressed() else 1.0
		tween.set_speed_scale(speed_multiplier)
		if anim_sprite:
			anim_sprite.speed_scale = 0.75 * speed_multiplier
			if anim_sprite.animation != walk_anim:
				anim_sprite.play(walk_anim)
		await get_tree().process_frame

	player.global_position = end_walk.global_position
	player.velocity = Vector2.ZERO

	player.speed = original_speed
	if anim_sprite:
		anim_sprite.speed_scale = original_anim_speed
		anim_sprite.play("idle " + player._facing_suffix(direction))

func start_player_king_dialogue() -> String:
	if INTRO_DIALOGUE == null:
		push_error("Dialogue resource not found: intro.dialogue")
		return "error"

	_intro_outcome = ""
	var balloon := DialogueManager.show_dialogue_balloon(INTRO_DIALOGUE, "throne_intro", [self])
	_register_fast_forward_balloon(balloon)
	await DialogueManager.dialogue_ended
	if _intro_outcome.is_empty():
		return "thanks_king"
	return _intro_outcome

func set_intro_outcome(outcome: String) -> void:
	if outcome == "fight_begins" and not _can_start_accusation_branch():
		_intro_outcome = "thanks_king"
		return
	_intro_outcome = outcome

func can_accuse_king() -> bool:
	return _can_start_accusation_branch()

func _can_start_accusation_branch() -> bool:
	return _accusation_branch_unlocked

func _resolve_accusation_branch_unlock() -> bool:
	return _check_required_clues_placeholder()

func _check_required_clues_placeholder() -> bool:
	# TODO: Implement node_12-specific clue/flag validation.
	return true

func start_post_fight_cutscene() -> void:
	if FINALE_DIALOGUE != null:
		var balloon := DialogueManager.show_dialogue_balloon(FINALE_DIALOGUE)
		_register_fast_forward_balloon(balloon)
		await DialogueManager.dialogue_ended
	await _show_ending_banner(
		"True Ending\n\nThe rightful king ascends the throne\nand orders immediate mobilization of the army."
	)

func _track_fast_forward_loop() -> void:
	while _fast_forward_enabled:
		_apply_fast_forward_to_dialogues()
		await get_tree().process_frame

func _register_fast_forward_balloon(balloon: Node) -> void:
	if balloon == null:
		return
	if _fast_forward_balloons.has(balloon):
		return
	_fast_forward_balloons.append(balloon)

func _apply_fast_forward_to_dialogues() -> void:
	var still_valid: Array[Node] = []
	var is_fast := _is_fast_forward_pressed()

	for balloon in _fast_forward_balloons:
		if balloon == null or not is_instance_valid(balloon):
			continue
		still_valid.append(balloon)

		var dialogue_label: Node = balloon.find_child("DialogueLabel", true, false)
		if dialogue_label == null:
			continue
		if not dialogue_label.has_method("set"):
			continue

		if is_fast:
			dialogue_label.set("seconds_per_step", 0.02 / maxf(1.0, hold_ctrl_dialogue_speed_multiplier))
			dialogue_label.set("seconds_per_pause_step", 0.30 / maxf(1.0, hold_ctrl_dialogue_speed_multiplier))
		else:
			dialogue_label.set("seconds_per_step", 0.02)
			dialogue_label.set("seconds_per_pause_step", 0.30)

	_fast_forward_balloons = still_valid

func _is_fast_forward_pressed() -> bool:
	return Input.is_key_pressed(KEY_CTRL)

func _wait_until_all_mages_defeated() -> void:
	while _count_alive_mages() > 0:
		await get_tree().create_timer(0.25).timeout

func _count_alive_mages() -> int:
	if mage_root == null:
		return 0
	var count := 0
	for child in mage_root.get_children():
		if child is Node12MageBase and is_instance_valid(child):
			count += 1
	return count

func _set_mage_ai_active(active: bool) -> void:
	if mage_root == null:
		return
	for child in mage_root.get_children():
		if child is Node12MageBase:
			var mage := child as Node12MageBase
			mage.set_physics_process(active)
			mage.set_process(active)

func _set_mage_group_visible(visible_state: bool) -> void:
	if mage_root != null:
		mage_root.visible = visible_state

func _force_clear_mages() -> void:
	if mage_root == null:
		return
	for child in mage_root.get_children():
		if child is Node12MageBase:
			child.queue_free()

func _soldier_back_away() -> void:
	if soldier_center == null:
		return
	var retreat_target := soldier_center.global_position + Vector2(0, 120)
	var tween := create_tween()
	tween.tween_property(soldier_center, "global_position", retreat_target, 0.8)
	await tween.finished

func _escort_player_by_soldier() -> void:
	if soldier_center == null:
		return
	var player_target := player.global_position + Vector2(0, 180)
	var soldier_target := soldier_center.global_position + Vector2(0, 180)
	var tween := create_tween()
	tween.tween_property(soldier_center, "global_position", soldier_target, 1.6)
	tween.parallel().tween_property(player, "global_position", player_target, 1.6)
	await tween.finished

func _show_ending_banner(text: String) -> void:
	pass
