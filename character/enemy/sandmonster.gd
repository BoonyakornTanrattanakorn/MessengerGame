extends CharacterBody2D

enum State { NORMAL, DRIED, DUST }

var state: State = State.NORMAL
var hp: int = 5
var move_speed: float = 60.0
var player: Node = null

@onready var animated_sprite = $AnimatedSprite2D
@onready var hurtbox = $Hurtbox

func _ready():
	hurtbox.add_to_group("enemy_hurtbox")
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	player = get_tree().root.find_child("Player", true, false)
	_update_state_visuals()

func _physics_process(delta):
	match state:
		State.NORMAL:
			_chase_player(delta)
		State.DRIED:
			velocity = Vector2.ZERO  # frozen
			move_and_slide()
		State.DUST:
			pass  # already dead

func _chase_player(delta):
	if player == null:
		return
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * move_speed
	move_and_slide()

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
			pass  # already dead

func _handle_damage_normal(amount: int, source: String):
	match source:
		"water_lv1":
			# No damage — just dry it
			print("[SandMonster] Water lv1 hit — drying!")
			_set_state(State.DRIED)
		"water_lv3":
			# Direct damage
			_reduce_hp(amount)
		"fire":
			# Direct damage
			_reduce_hp(amount)
		"wind":
			# Wind does nothing to normal state
			print("[SandMonster] Wind has no effect in normal state")
		_:
			_reduce_hp(amount)

func _handle_damage_dried(amount: int, source: String):
	match source:
		"wind":
			# Wind kills dried monster instantly
			print("[SandMonster] Wind hit dried monster — crumbling to dust!")
			_set_state(State.DUST)
		"water_lv1":
			# Already dried, no effect
			print("[SandMonster] Already dried")
		"fire":
			# Fire can damage dried state
			_reduce_hp(amount)
		"water_lv3":
			# Heavy water also damages
			_reduce_hp(amount)
		_:
			_reduce_hp(amount)

func _reduce_hp(amount: int):
	hp -= amount
	print("[SandMonster] HP: ", hp)
	if hp <= 0:
		_die()

func _set_state(new_state: State):
	state = new_state
	_update_state_visuals()
	print("[SandMonster] State changed to: ", State.keys()[new_state])

func _die():
	print("[SandMonster] Died from damage")
	_set_state(State.DUST)
	# Wait for dust animation then free
	await animated_sprite.animation_finished
	queue_free()

func _on_hurtbox_area_entered(area: Area2D):
	# Get damage and source from projectile
	var dmg = area.get("damage") if area.get("damage") != null else 0
	var source = area.get("source") if area.get("source") != null else ""
	print("[SandMonster] Hit by: ", area.name, " source: ", source, " dmg: ", dmg)
	take_damage(dmg, source)
	area.queue_free()
