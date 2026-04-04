extends PanelContainer

@export var player: CharacterBody2D

@onready var player_icon = $TextureRect2

func _ready():
	player_icon.pivot_offset = player_icon.size / 2

func _process(delta):

	if player == null:
		return

	player_icon.rotation = player.last_direction.angle() + PI / 2
