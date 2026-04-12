extends StaticBody2D

@export var rock_texture: Texture2D

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var hurt_zone = $HurtZone

func _ready():
	add_to_group("breakable")
	collision.disabled = false
	hurt_zone.body_entered.connect(_on_hurt_zone_body_entered)

func _on_hurt_zone_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage()

func break_obstacle():
	# Disable both collision and hurt when broken
	collision.set_deferred("disabled", true)
	hurt_zone.monitoring = false
	sprite.texture = rock_texture
	await get_tree().create_timer(0.3).timeout
	queue_free()
