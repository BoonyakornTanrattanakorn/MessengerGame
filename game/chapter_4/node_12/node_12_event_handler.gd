extends LevelEventHandler

signal hallway_thoughts_finished
signal bad_end_dialogue_finished
signal fight_sequence_finished

const INTRO_DIALOGUE := preload("res://game/chapter_4/node_12/dialogue/intro.dialogue")
const FINALE_DIALOGUE := preload("res://game/chapter_4/node_12/dialogue/finale.dialogue")
const NODE_12_EVENT_UTILS := preload("res://game/chapter_4/node_12/node_12_event_utils.gd")

@onready var player_bad_end_walk: Path2D = $PathAndMarker/PlayerBadEndWalk
@onready var intro_walk: Path2D = $"PathAndMarker/IntroWalk"
@onready var fight_begin: Marker2D = $"PathAndMarker/FightBegin"
@onready var throne_marker: Marker2D = $"PathAndMarker/Throne"
@onready var solder_escort_king: Path2D = $PathAndMarker/SolderEscortKing

@onready var king: CharacterBody2D = $"NPC/King"
@onready var soldier_escort: CharacterBody2D = $"NPC/SoldierEscort"
@onready var mage_root: Node2D = $"Mage"

@export_group("Debug")
@export var debug_skip_mage_fight: bool = true
@export_group("Cutscene Fast Forward")
@export var hold_ctrl_walk_speed_multiplier: float = 10.0
@export var hold_ctrl_dialogue_speed_multiplier: float = 10.0

var _waiting_for_hallway_thoughts: bool = false
var _hallway_thoughts_done: bool = false
var _waiting_for_bad_end_dialogue: bool = false
var _bad_end_dialogue_done: bool = false
var _fight_sequence_started: bool = false
var _fight_sequence_done: bool = false
var _fast_forward_enabled: bool = false
var _fast_forward_balloons: Array[Node] = []
var _accusation_branch_unlocked: bool = true

func _ready() -> void:

	assert(intro_walk != null)
	_set_mage_group_visible(false)
	_set_mage_ai_active(false)

	var minimap = get_node_or_null("/root/GameScene/Minimap")
	if not minimap:
		minimap = get_tree().current_scene.get_node_or_null("Minimap")
	if minimap:
		minimap.hide()

	
func handle_intro_for_level() -> void:
	if not GameState.chap4_node12_shown:
		GameState.chap4_node12_shown = true
		
		var original_input_locked = player.is_in_dialogue
		var original_camera_pan = player.is_camera_panning

		# Play intro BGM (orchestral_mission)
		BGMManager.play_bgm("orchestral_mission", -8.0)


		player.is_in_dialogue = true
		player.is_camera_panning = true
		_accusation_branch_unlocked = _resolve_accusation_branch_unlock()
		_fight_sequence_started = false
		_fight_sequence_done = false
		_fast_forward_enabled = true
		_track_fast_forward_loop()

		show_player_thoughts()
		await slow_walk_intro()
		if _waiting_for_hallway_thoughts and not _hallway_thoughts_done:
			await hallway_thoughts_finished
		await show_king_cutscene()
		await start_player_king_dialogue()

		if _fight_sequence_started:
			if not _fight_sequence_done:
				await fight_sequence_finished
			await start_post_fight_cutscene()
		else:
			await normal_ending()

		# Restore intro/outro BGM after fight or ending
		BGMManager.play_bgm("orchestral_mission", -8.0)

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


func show_king_cutscene() -> void:
	if SFXManager != null:
		SFXManager.play_event("ui.confirm")
	if king != null and king.has_node("AnimatedSprite2D"):
		var sprite: AnimatedSprite2D = king.get_node("AnimatedSprite2D")
		sprite.play("idle")
	await get_tree().create_timer(0.4).timeout

func normal_ending() -> void:
	_show_bad_end_walk_out_dialogue()
	await _bad_end_walk_out()
	if _waiting_for_bad_end_dialogue and not _bad_end_dialogue_done:
		await bad_end_dialogue_finished
	_show_ending_banner()

func _show_bad_end_walk_out_dialogue() -> void:
	if INTRO_DIALOGUE == null:
		_bad_end_dialogue_done = true
		_waiting_for_bad_end_dialogue = false
		return

	_bad_end_dialogue_done = false
	_waiting_for_bad_end_dialogue = true
	if not DialogueManager.dialogue_ended.is_connected(_on_bad_end_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_bad_end_dialogue_ended)
	var balloon := DialogueManager.show_dialogue_balloon(INTRO_DIALOGUE, "thanks_king", [self])
	_register_fast_forward_balloon(balloon)

func _on_bad_end_dialogue_ended(resource: DialogueResource) -> void:
	if not _waiting_for_bad_end_dialogue:
		return
	if resource != INTRO_DIALOGUE:
		return
	_waiting_for_bad_end_dialogue = false
	_bad_end_dialogue_done = true
	if DialogueManager.dialogue_ended.is_connected(_on_bad_end_dialogue_ended):
		DialogueManager.dialogue_ended.disconnect(_on_bad_end_dialogue_ended)
	bad_end_dialogue_finished.emit()

func equip_fire_power() -> void:
	player.playerAttribute = "fire"
	if player.hud:
		player.hud.set_current_skill("fire")

func start_fight_sequence() -> void:
	_fight_sequence_started = true
	if _fight_sequence_done:
		fight_sequence_finished.emit()
		return

	# Play fight BGM
	BGMManager.play_bgm("fire_blade", -12.0)
	SFXManager.play_event("node12.cutscene.reveal")

	_set_mage_group_visible(true)
	_set_mage_ai_active(false)

	_set_mage_ai_active(true)
	player.is_in_dialogue = false
	player.is_camera_panning = false

	if debug_skip_mage_fight:
		await get_tree().create_timer(3.0).timeout
		_force_clear_mages()
		await get_tree().process_frame

	await _wait_until_all_mages_defeated()
	player.is_in_dialogue = true
	player.is_camera_panning = true
	_set_mage_ai_active(false)
	_fight_sequence_done = true
	fight_sequence_finished.emit()

func player_killed_sequence() -> void:
	_show_ending_banner()

func slow_walk_intro() -> void:
	player.is_in_dialogue = true
	await NODE_12_EVENT_UTILS.walk_entity_along_path(
		self,
		player,
		intro_walk,
		70.0,
		hold_ctrl_walk_speed_multiplier,
		0.75
	)

func _warp_player_to_intro_walk_end_for_finale() -> void:
	if player == null or intro_walk == null or intro_walk.curve == null:
		return

	var path_length := intro_walk.curve.get_baked_length()
	if path_length <= 0.0:
		return

	var scene_root := get_tree().current_scene
	if scene_root == null:
		return

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 50
	var fade_rect := ColorRect.new()
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	fade_layer.add_child(fade_rect)
	scene_root.add_child(fade_layer)

	if SFXManager != null:
		SFXManager.play_event("node12.cutscene.fade")

	var fade_in_tween := create_tween()
	fade_in_tween.tween_property(fade_rect, "color:a", 1.0, 0.25)
	await fade_in_tween.finished

	var end_local := intro_walk.curve.sample_baked(path_length, true)
	var end_world := intro_walk.to_global(end_local)
	player.global_position = end_world
	player.velocity = Vector2.ZERO

	var end_dir := NODE_12_EVENT_UTILS.get_path_end_direction(intro_walk, Vector2.DOWN)
	_set_player_facing_idle(end_dir)

	await get_tree().process_frame

	var fade_out_tween := create_tween()
	fade_out_tween.tween_property(fade_rect, "color:a", 0.0, 0.25)
	await fade_out_tween.finished

	fade_layer.queue_free()

func start_player_king_dialogue() -> void:
	if INTRO_DIALOGUE == null:
		push_error("Dialogue resource not found: intro.dialogue")
		return

	var balloon := DialogueManager.show_dialogue_balloon(INTRO_DIALOGUE, "throne_intro", [self])
	_register_fast_forward_balloon(balloon)
	await DialogueManager.dialogue_ended

func choose_thanks_king() -> void:
	pass

func choose_accuse_king() -> void:
	if not _can_start_accusation_branch():
		return

func can_accuse_king() -> bool:
	return _can_start_accusation_branch()

func _can_start_accusation_branch() -> bool:
	return _accusation_branch_unlocked

func _resolve_accusation_branch_unlock() -> bool:
	return _check_required_clues_placeholder()

func _check_required_clues_placeholder() -> bool:
	# TODO: Implement node_12-specific clue/flag validation.
	return _accusation_branch_unlocked

func start_post_fight_cutscene() -> void:
	# Restore outro BGM (orchestral_mission)
	if BGMManager != null:
		BGMManager.play_bgm("orchestral_mission", -8.0)


	if FINALE_DIALOGUE != null:
		var balloon := DialogueManager.show_dialogue_balloon(FINALE_DIALOGUE, "start", [self])
		_register_fast_forward_balloon(balloon)
		await DialogueManager.dialogue_ended
	_show_ending_banner()

func _track_fast_forward_loop() -> void:
	while _fast_forward_enabled:
		_fast_forward_balloons = NODE_12_EVENT_UTILS.apply_fast_forward_to_dialogues(
			_fast_forward_balloons,
			hold_ctrl_dialogue_speed_multiplier,
			NODE_12_EVENT_UTILS.is_fast_forward_pressed()
		)
		await get_tree().process_frame

func _register_fast_forward_balloon(balloon: Node) -> void:
	_fast_forward_balloons = NODE_12_EVENT_UTILS.register_fast_forward_balloon(_fast_forward_balloons, balloon)

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
			(child as Node12MageBase).die()

func _get_mages_for_reveal() -> Array[Node12MageBase]:
	var mages: Array[Node12MageBase] = []
	if mage_root == null:
		return mages
	for child in mage_root.get_children():
		if child is Node12MageBase and is_instance_valid(child):
			mages.append(child as Node12MageBase)
	return mages

func _fade_to_black_then_warp_player() -> void:
	if fight_begin == null:
		return

	var scene_root := get_tree().current_scene
	if scene_root == null:
		player.global_position = fight_begin.global_position
		return

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 50
	var fade_rect := ColorRect.new()
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	fade_layer.add_child(fade_rect)
	scene_root.add_child(fade_layer)

	var fade_in_tween := create_tween()
	if SFXManager != null:
		SFXManager.play_event("node12.cutscene.fade")
	fade_in_tween.tween_property(fade_rect, "color:a", 1.0, 0.25)
	await fade_in_tween.finished

	player.global_position = fight_begin.global_position
	player.velocity = Vector2.ZERO
	await get_tree().process_frame

	var fade_out_tween := create_tween()
	fade_out_tween.tween_property(fade_rect, "color:a", 0.0, 0.25)
	await fade_out_tween.finished

	fade_layer.queue_free()

func _fade_out_king_for_finale() -> void:
	if king == null or not is_instance_valid(king):
		return

	var scene_root := get_tree().current_scene
	if scene_root == null:
		king.visible = false
		return

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 50
	var fade_rect := ColorRect.new()
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	fade_layer.add_child(fade_rect)
	scene_root.add_child(fade_layer)

	if SFXManager != null:
		SFXManager.play_event("node12.cutscene.fade")

	var fade_in_tween := create_tween()
	fade_in_tween.tween_property(fade_rect, "color:a", 1.0, 0.25)
	await fade_in_tween.finished

	king.visible = false
	king.set_physics_process(false)
	king.set_process(false)
	var king_collision := king.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if king_collision != null:
		king_collision.disabled = true

	await get_tree().process_frame

	var fade_out_tween := create_tween()
	fade_out_tween.tween_property(fade_rect, "color:a", 0.0, 0.25)
	await fade_out_tween.finished

	fade_layer.queue_free()

func _walk_player_to_throne() -> void:
	if player == null or throne_marker == null:
		return

	var player_to_throne := Path2D.new()
	var curve := Curve2D.new()
	player_to_throne.curve = curve
	player_to_throne.global_position = player.global_position
	curve.add_point(Vector2.ZERO)
	curve.add_point(throne_marker.global_position - player.global_position)
	add_child(player_to_throne)

	await NODE_12_EVENT_UTILS.walk_entity_along_path(
		self,
		player,
		player_to_throne,
		70.0,
		hold_ctrl_walk_speed_multiplier,
		0.75
	)

	if is_instance_valid(player_to_throne):
		player_to_throne.queue_free()

	_set_player_facing_idle(Vector2.DOWN)

func _soldier_escort_king_out() -> void:
	if king == null or soldier_escort == null or solder_escort_king == null or solder_escort_king.curve == null:
		return

	var curve := solder_escort_king.curve
	var path_length := curve.get_baked_length()
	if path_length <= 0.0:
		return

	# Phase 1: soldier walks to king first.
	var king_guard_offset := Vector2(20.0, 0.0)
	await _walk_npc_to_world_position(soldier_escort, king.global_position + king_guard_offset, 70.0)

	var move_speed := 70.0
	var king_local := solder_escort_king.to_local(king.global_position)
	var start_offset := clampf(curve.get_closest_offset(king_local), 0.0, path_length)
	var remaining_length := path_length - start_offset
	if remaining_length <= 0.0:
		_set_npc_idle_animation(king)
		_set_npc_idle_animation(soldier_escort)
		return

	var duration := remaining_length / maxf(1.0, move_speed)
	var king_offset := Vector2(-20.0, 0.0)
	var soldier_offset := king_guard_offset
	var last_direction := Vector2.UP

	var tween := create_tween()
	tween.tween_method(func(progress: float) -> void:
		if not is_instance_valid(king) or not is_instance_valid(soldier_escort):
			return
		var distance_along := start_offset + (progress * remaining_length)
		var local_pos := curve.sample_baked(distance_along, true)
		var world_pos := solder_escort_king.to_global(local_pos)

		var lookback := minf(distance_along, 4.0)
		var prev_local := curve.sample_baked(distance_along - lookback, true)
		var prev_world := solder_escort_king.to_global(prev_local)
		var direction := (world_pos - prev_world).normalized()
		if direction.length_squared() > 0.0001:
			last_direction = direction

		king.global_position = world_pos + king_offset
		soldier_escort.global_position = world_pos + soldier_offset

		_set_npc_walk_animation(king, last_direction)
		_set_npc_walk_animation(soldier_escort, last_direction)
	, 0.0, 1.0, duration)

	while tween.is_running():
		if not is_inside_tree():
			tween.kill()
			return
		if not is_instance_valid(king) or not is_instance_valid(soldier_escort):
			tween.kill()
			return
		var tree := get_tree()
		if tree == null:
			tween.kill()
			return
		var speed_multiplier := hold_ctrl_walk_speed_multiplier if NODE_12_EVENT_UTILS.is_fast_forward_pressed() else 1.0
		tween.set_speed_scale(speed_multiplier)
		await tree.process_frame

	_set_npc_idle_animation(king)
	_set_npc_idle_animation(soldier_escort)

func _walk_npc_to_world_position(entity: CharacterBody2D, target_world_pos: Vector2, move_speed: float) -> void:
	if entity == null:
		return

	var start_pos := entity.global_position
	var distance := start_pos.distance_to(target_world_pos)
	if distance <= 1.0:
		_set_npc_idle_animation(entity)
		return

	var duration := distance / maxf(1.0, move_speed)
	var tween := create_tween()
	tween.tween_method(func(progress: float) -> void:
		if not is_instance_valid(entity):
			return
		var world_pos := start_pos.lerp(target_world_pos, progress)
		var direction := (target_world_pos - entity.global_position).normalized()
		if direction.length_squared() > 0.0001:
			_set_npc_walk_animation(entity, direction)
		entity.global_position = world_pos
	, 0.0, 1.0, duration)

	while tween.is_running():
		if not is_inside_tree():
			tween.kill()
			return
		if not is_instance_valid(entity):
			tween.kill()
			return
		var tree := get_tree()
		if tree == null:
			tween.kill()
			return
		var speed_multiplier := hold_ctrl_walk_speed_multiplier if NODE_12_EVENT_UTILS.is_fast_forward_pressed() else 1.0
		tween.set_speed_scale(speed_multiplier)
		await tree.process_frame

	_set_npc_idle_animation(entity)

func _set_player_facing_idle(direction: Vector2) -> void:
	if player == null:
		return

	if player.has_method("set_facing_direction"):
		player.call("set_facing_direction", direction)

	var sprite := player.get("animated_sprite") as AnimatedSprite2D
	if sprite == null or not player.has_method("_facing_suffix"):
		return

	var suffix := String(player.call("_facing_suffix", direction))
	if suffix.is_empty():
		return

	var idle_anim := "idle " + suffix
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(idle_anim):
		sprite.play(idle_anim)

func _set_npc_walk_animation(entity: CharacterBody2D, direction: Vector2) -> void:
	if entity == null:
		return
	var sprite := entity.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		return

	var anim := "walk_down"
	if absf(direction.x) >= absf(direction.y):
		anim = "walk_right" if direction.x >= 0.0 else "walk_left"
	else:
		anim = "walk_down" if direction.y >= 0.0 else "walk_up"

	if sprite.sprite_frames.has_animation(anim) and sprite.animation != anim:
		sprite.play(anim)

func _set_npc_idle_animation(entity: CharacterBody2D) -> void:
	if entity == null:
		return
	var sprite := entity.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		return
	if sprite.sprite_frames.has_animation("idle") and sprite.animation != "idle":
		sprite.play("idle")

func _reveal_mages_with_camera_pan() -> void:
	_set_mage_group_visible(true)
	await get_tree().process_frame

	var mages := _get_mages_for_reveal()
	if mages.is_empty():
		return

	for mage in mages:
		mage.visible = true
		mage.modulate.a = 0.0

	var camera: Camera2D = player.get_node_or_null("Camera2D")
	var scene_root := get_tree().current_scene
	var camera_was_reparented := false

	if camera != null and scene_root != null and camera.get_parent() != scene_root:
		camera.reparent(scene_root)
		camera_was_reparented = true

	if camera != null:
		player.is_camera_panning = true

	for mage in mages:
		if not is_instance_valid(mage):
			continue

		if camera != null:
			var pan_tween := create_tween()
			pan_tween.tween_property(camera, "global_position", mage.global_position, 0.45)
			await pan_tween.finished

		if SFXManager != null:
			SFXManager.play_event("node12.cutscene.reveal")

		var reveal_tween := create_tween()
		reveal_tween.tween_property(mage, "modulate:a", 1.0, 0.35)
		await reveal_tween.finished
		await get_tree().create_timer(0.1).timeout

	if camera != null and camera_was_reparented:
		camera.reparent(player)
		camera.position = Vector2.ZERO

func _bad_end_walk_out() -> void:
	await NODE_12_EVENT_UTILS.walk_entity_along_path(
		self,
		player,
		player_bad_end_walk,
		70.0,
		hold_ctrl_walk_speed_multiplier,
		0.75
	)

func _show_ending_banner() -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		get_tree().change_scene_to_file("res://game/chapter_4/ending/ending.tscn")
		return

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 60
	var fade_rect := ColorRect.new()
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	fade_layer.add_child(fade_rect)
	scene_root.add_child(fade_layer)

	if SFXManager != null:
		SFXManager.play_event("node12.cutscene.fade")

	var fade_tween := create_tween()
	fade_tween.tween_property(fade_rect, "color:a", 1.0, 1.2)
	await fade_tween.finished

	get_tree().change_scene_to_file("res://game/chapter_4/ending/ending.tscn")
