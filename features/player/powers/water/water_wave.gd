extends Area2D

var direction: Vector2 = Vector2.RIGHT
var level: int = 1
var damage: int = 1
var source_element: String = "water"

# Per level: [speed, max_distance, scale]
const LEVEL_SETTINGS = [
	{"speed": 200.0, "distance": 80.0,  "scale": Vector2(1.0, 1.0)},  # level 1
	{"speed": 180.0, "distance": 150.0, "scale": Vector2(0.3, 0.3)},  # level 2
	{"speed": 160.0, "distance": 150.0, "scale": Vector2(0.35, 0.35)},  # level 3
]

var speed: float = 200.0
var max_distance: float = 80.0
var traveled: float = 0.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision = $CollisionShape2D

func _ready():
	var settings = LEVEL_SETTINGS[level - 1]
	speed        = settings["speed"]
	max_distance = settings["distance"]
	scale        = settings["scale"]
	damage       = level

	# Rotate entire node to face direction
	rotation = direction.angle()

	# Play correct animation
	animated_sprite.play("wave_%d" % level)
	
	# Connect body entered
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	var step = direction * speed * delta
	position += step
	traveled += step.length()
	
	# Animate scale growing slightly as it travels (optional visual effect)
	if level >= 2:
		var grow = 1.0 + (traveled / max_distance) * 0.2
		animated_sprite.scale = Vector2(grow, 1.0)
	
	if traveled >= max_distance:
		_on_expire()


func _on_body_entered(body):
	if body.is_in_group("player_hurtbox"):
		return  # ignore player
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage, source_element)
	queue_free()

func _on_expire():
	# Play a fade out or just free
	queue_free()
