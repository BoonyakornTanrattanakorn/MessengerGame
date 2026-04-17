extends Node2D

signal organ_destroyed

@export var normal_texture: Texture2D
@export var severe_texture: Texture2D
@export var broken_texture: Texture2D

@onready var sprite = $Sprite2D
@onready var hurt_zone = $HurtZone

const MAX_HP = 80
const OFFSET = Vector2(300, -150)

var current_hp = MAX_HP
var camera: Camera2D

func _ready():
	add_to_group("breakable")  # ← add to breakable group so blast_skill detects it
	hurt_zone.body_entered.connect(_on_hurt_zone_body_entered)
	camera = get_tree().get_first_node_in_group("camera")
	update_sprite()

func _process(_delta):
	if camera:
		global_position = camera.global_position + OFFSET

func take_hit():
	current_hp -= 1
	flash_damage()
	update_sprite()
	if current_hp <= 0:
		destroy()

func update_sprite():
	if current_hp >= 80:
		sprite.texture = normal_texture
	elif current_hp <= 35:
		sprite.texture = severe_texture

func flash_damage():
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE
	await get_tree().create_timer(0.05).timeout
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE

func destroy():
	hurt_zone.monitoring = false
	sprite.texture = broken_texture
	await get_tree().create_timer(0.5).timeout
	emit_signal("organ_destroyed")
	queue_free()

func _on_hurt_zone_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage()
