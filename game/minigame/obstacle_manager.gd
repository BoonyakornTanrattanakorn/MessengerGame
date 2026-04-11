extends Node2D

@export var obstacle_scenes: Array[PackedScene]
@export var spawn_rate := 2.0
@export var spawn_x := 800
@export var ground_y := 300

func _ready():
	spawn_loop()

var running := false

func start(delay := 1.0):
	await get_tree().create_timer(delay).timeout
	running = true
	spawn_loop()

func spawn_loop():
	while running:
		await get_tree().create_timer(randf_range(1.0, 2.0)).timeout
		spawn_obstacle()


func spawn_obstacle():
	var scene = obstacle_scenes.pick_random()
	var obs = scene.instantiate()
	add_child(obs)

	if obs.name.contains("Bird"):
		obs.position = Vector2(spawn_x, randf_range(150, 250))
	else:
		obs.position = Vector2(spawn_x, ground_y)
