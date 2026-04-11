extends Node2D

const GAME_TIME = 90.0
var time_left: float = GAME_TIME
var running: bool = false


@onready var player = $Player
@onready var obstacle_manager = $ObstacleManager
@onready var death_zone = $DeathZone
@onready var hp_label = $UI/HPLabel
@onready var timer_label = $UI/TimerLabel
@onready var coin_label = $UI/CoinLabel

func _ready():
	player.hp_changed.connect(_on_hp_changed)
	player.player_died.connect(_on_player_died)
	player.coin_collected.connect(_on_coin_collected)
	death_zone.body_entered.connect(_on_death_zone_entered)
	hp_label.text = "HP: 3"
	coin_label.text = "Coins: 0"
	timer_label.text = "1:30"
	_start_game()

func _start_game():
	time_left = GAME_TIME
	running = true
	obstacle_manager.start(1)

func _process(delta):
	if not running:
		return
	time_left -= delta
	if time_left <= 0:
		time_left = 0
		running = false
		obstacle_manager.stop()
		print("Time up! Coins: ", player.coins)
		return
	var mins = int(time_left) / 60
	var secs = int(time_left) % 60
	timer_label.text = "%d:%02d" % [mins, secs]

func _on_hp_changed(_hp: int):
	hp_label.text = "HP: " + str(player.hp)

func _on_coin_collected(total: int):
	coin_label.text = "Coins: " + str(total)

func _on_player_died():
	running = false
	obstacle_manager.stop()
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()

func _on_death_zone_entered(body):
	if body.is_in_group("player"):
		player.fall_into_hole()
