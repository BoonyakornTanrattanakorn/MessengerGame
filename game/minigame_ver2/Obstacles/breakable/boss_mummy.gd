extends StaticBody2D

#@export var rock_texture: Texture2D
@export var max_health: int = 3  # set in Inspector per obstacle

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var hurt_zone = $HurtZone

var current_health: int

func _ready():
	add_to_group("breakable")
	current_health = max_health
	collision.disabled = false
	hurt_zone.body_entered.connect(_on_hurt_zone_body_entered)

func _on_hurt_zone_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage()

func take_hit():
	current_health -= 1
	flash_damage()
	
	if current_health <= 0:
		break_obstacle()

func flash_damage():
	# Red blink effect
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE
	await get_tree().create_timer(0.05).timeout
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE

func break_obstacle():
	collision.set_deferred("disabled", true)
	hurt_zone.monitoring = false
	#sprite.texture = rock_texture
	#await get_tree().create_timer(0.3).timeout
	queue_free()
