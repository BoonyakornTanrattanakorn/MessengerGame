extends Area2D

signal lever_pulled

@export var is_pulled := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _player_in_range := false

func _ready() -> void:
	sprite.play("off")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)

func _process(_delta: float) -> void:
	if _player_in_range and not is_pulled and Input.is_action_just_pressed("interact"):
		_pull()

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		_player_in_range = false

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("wind_wave") or area.name.to_lower().contains("wind"):
		_pull()
		if area.has_method("queue_free"):
			area.queue_free()

func _pull() -> void:
	if is_pulled:
		return
	is_pulled = true
	sprite.play("on")
	lever_pulled.emit()
