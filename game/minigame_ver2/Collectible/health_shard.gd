# health_shard.gd
extends Area2D

@export var shard_value: int = 1  # how many shards this pickup gives

func _ready():
	add_to_group("shard")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.add_shard(shard_value)
		queue_free()
