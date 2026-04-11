extends Camera2D

# Cookie Run style: player is locked to left side of screen
# Camera follows only horizontally, no lag

@export var target: NodePath
var player: Node2D
var fixed_y: float 

func _ready():
	player = get_node(target)
	# Keep player at ~20% from left edge
	#offset.x = -get_viewport_rect().size.x * 0.35
	offset = Vector2(60, -20)
	fixed_y = player.global_position.y 
	
func _process(_delta):
	if player:
		# Only track X axis, Y stays fixed
		global_position.x = player.global_position.x
		global_position.y = fixed_y
