extends CharacterBody2D

enum State { NORMAL, DRIED, DUST }

var ATTACK_RANGE: float = 70.0
var ATTACK_DAMAGE: int = 1
var ATTACK_COOLDOWN: float = 1.5
var DETECTION_RANGE: float = 300.0
var AGGRO_RANGE: float = 400.0
var is_aggro: bool = false

var state: State = State.NORMAL
var hp: int = 5
var move_speed: float = 60.0
var player: Node = null
var attacking: bool = false
var attack_timer: float = 0.0
var attack_sfx: AudioStreamPlayer

@onready var animated_sprite = $AnimatedSprite2D
@onready var hurtbox = $Hurtbox

func _ready():
	attack_sfx = AudioStreamPlayer.new()
	attack_sfx.stream = load("res://assets/audio/punch-sound-effect-hd-1-y-5-koz (1).ogg")
	add_child(attack_sfx)
	add_to_group("enemy")
	hurtbox.add_to_group("enemy_hurtbox")
	hurtbox.collision_mask |= 4  # include wind's collision layer (layer 3)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	player = get_tree().root.find_child("Player", true, false)
	_update_state_visuals()

func _check_fairy_proximity() -> void:
	for fairy in get_tree().get_nodes_in_group("water_fairy"):
		if global_position.distance_to(fairy.global_position) < 40.0:
			take_damage(1, "water_lv1")
			return

func _physics_process(delta):
	if state == State.NORMAL:
		_check_fairy_proximity()
	match state:
		State.NORMAL:
			if attack_timer > 0.0:
				attack_timer -= delta
			if attacking:
				velocity = Vector2.ZERO
				move_and_slide()
				return
			if player != null:
				var dist = global_position.distance_to(player.global_position)
				if dist > AGGRO_RANGE * 1.5:
					is_aggro = false
				if dist <= DETECTION_RANGE:
					is_aggro = true
				var current_range = AGGRO_RANGE if is_aggro else DETECTION_RANGE

				if dist <= ATTACK_RANGE and attack_timer <= 0.0:
					_start_attack()
					return

				if dist <= current_range:
					_chase_player(delta)
				else:
					velocity = Vector2.ZERO
					move_and_slide()
					return

		State.DRIED:
			velocity = Vector2.ZERO
			move_and_slide()
		State.DUST:
			pass

func _chase_player(delta):
	if player == null:
		return
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * move_speed
	move_and_slide()

func _start_attack():
	attacking = true
	velocity = Vector2.ZERO
	animated_sprite.play("attack")
	await animated_sprite.animation_finished
	_do_attack_hit()
	await get_tree().create_timer(1.0).timeout
	attacking = false

func _do_attack_hit():
	attack_sfx.play()
	if player != null and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= ATTACK_RANGE:
			if player.has_node("HealthComponent"):
				player.get_node("HealthComponent").take_damage(ATTACK_DAMAGE)
			elif player.has_method("take_damage"):
				player.take_damage(ATTACK_DAMAGE)
	attack_timer = ATTACK_COOLDOWN
	if state == State.NORMAL:
		animated_sprite.play("normal")

func _update_state_visuals():
	match state:
		State.NORMAL:
			animated_sprite.play("normal")
		State.DRIED:
			animated_sprite.play("dried")
		State.DUST:
			animated_sprite.play("dust")

func take_damage(amount: int, source: String = ""):
	match state:
		State.NORMAL:
			_handle_damage_normal(amount, source)
		State.DRIED:
			_handle_damage_dried(amount, source)
		State.DUST:
			pass

func _handle_damage_normal(amount: int, source: String):
	match source:
		"water_lv1":
			_set_state(State.DRIED)
		"fire":
			_reduce_hp(amount)
		"wind":
			pass
		_:
			_reduce_hp(amount)

func _handle_damage_dried(amount: int, source: String):
	match source:
		"wind":
			_die()
		"water_lv1", "water_lv2", "water_lv3":
			pass
		"fire":
			_reduce_hp(amount)
		_:
			_reduce_hp(amount)

func _reduce_hp(amount: int):
	hp -= amount
	if hp <= 0:
		_die()

func _set_state(new_state: State):
	state = new_state
	_update_state_visuals()

func _die():
	_set_state(State.DUST)
	await animated_sprite.animation_finished
	queue_free()

func _on_hurtbox_area_entered(area: Area2D):
	if not area.is_in_group("player_projectile"):
		return
	var dmg = area.get("damage") if area.get("damage") != null else 0
	var source = area.get("source") if area.get("source") != null else ""
	take_damage(dmg, source)
	area.queue_free()
