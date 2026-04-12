extends Area2D

var _player_in_range: bool = false
var _collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if _player_in_range and Input.is_action_just_pressed("interact"):
		_collect()

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		_player_in_range = false

func _collect() -> void:
	if _collected:
		return
	
	if Node4State.first_insignia_obtained:
		return
	
	Node4State.obtain_first_insignia()
	print("Obtained First Insignia")
	
	_collected = true
	
	var shape := $CollisionShape2D
	if shape:
		shape.set_deferred("disabled", true)
	
	hide() # or queue_free()
