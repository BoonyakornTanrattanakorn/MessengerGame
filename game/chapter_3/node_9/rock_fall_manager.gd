# RockFallManager.gd
extends Node2D

const ROCK_COUNTS = {1: 1, 2: 2, 3: 3}    # rocks per phase
const SPAWN_INTERVAL = 4.0                  # seconds between waves
const SPAWN_RADIUS = 80.0                   # how close to player rocks spawn
const MIN_DISTANCE = 40.0                   # minimum distance from player

var current_phase: int = 1
var spawn_timer: float = 2.0               # start first wave after 2s
var active: bool = false
var player_ref = null

@export var rock_scene: PackedScene = preload("res://game/chapter_3/node_9/RockFall.tscn")

func _ready():
	player_ref = get_tree().root.find_child("Player", true, false)

func start(phase: int):
	current_phase = phase
	active = true
	spawn_timer = 2.0

func stop():
	active = false
	# Clear existing rocks
	for child in get_children():
		child.queue_free()

func _process(delta):
	if not active or player_ref == null:
		return
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer = SPAWN_INTERVAL
		_spawn_wave()

func _spawn_wave():
	var count = ROCK_COUNTS.get(current_phase, 1)
	var positions = _get_spawn_positions(count)
	for pos in positions:
		var rock = rock_scene.instantiate()
		rock.position = pos
		add_child(rock)
		print("[RockFallManager] Spawned rock at: ", pos)

func _get_spawn_positions(count: int) -> Array:
	var positions = []
	var attempts = 0
	while positions.size() < count and attempts < 30:
		attempts += 1
		# Random offset near player
		var angle = randf() * TAU
		var dist = randf_range(MIN_DISTANCE, SPAWN_RADIUS)
		var offset = Vector2(cos(angle), sin(angle)) * dist
		var pos = player_ref.global_position + offset

		# Make sure rocks don't overlap each other
		var too_close = false
		for existing in positions:
			if pos.distance_to(existing) < 50.0:
				too_close = true
				break
		if not too_close:
			positions.append(pos)
	return positions
