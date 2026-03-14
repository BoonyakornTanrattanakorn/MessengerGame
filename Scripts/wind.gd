extends Area2D

var speed = 400.0
var direction = Vector2.RIGHT
var lifetime = 1.0

func _ready():
	# สั่งให้ลบตัวเองทิ้งเมื่อครบเวลา
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("walls") or body.is_in_group("enemies"):
		queue_free()
