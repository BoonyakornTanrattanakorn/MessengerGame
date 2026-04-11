extends CanvasLayer

@onready var hp_label = $HPLabel
@onready var timer_label = $TimerLabel
@onready var coin_label = $CoinLabel

var time := 0

func _ready():
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		player.hp_changed.connect(_on_hp_changed)
		player.coin_changed.connect(_on_coin_changed)
		player.player_died.connect(_on_player_died)
		player.coin_collected.connect(_on_coin_collected)
		
func _process(delta):
	time += delta
	timer_label.text = "Time: " + str(int(time))

	var player = get_tree().get_first_node_in_group("player")
	if player:
		hp_label.text = "HP: " + str(player.hp)
		coin_label.text = "Coin: " + str(player.coin)

func _on_hp_changed(value):
	$HPLabel.text = "HP: " + str(value)

func _on_coin_changed(value):
	$CoinLabel.text = "Coin: " + str(value)

func _on_player_died():
	print("Game Over")

func _on_coin_collected():
	print("เก็บเหรียญ!")
