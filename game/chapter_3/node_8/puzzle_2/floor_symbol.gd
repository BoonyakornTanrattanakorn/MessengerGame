extends Area2D

signal symbol_stepped_on(symbol_id: int)

@export var symbol_id: int = 1

var _is_active := false

func _ready() -> void:
	hide()
	# Disable collision so wind can't interact with hidden symbol
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not _is_active:
		return
	if body.name == "Player":
		symbol_stepped_on.emit(symbol_id)

func activate() -> void:
	_is_active = true
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

func deactivate() -> void:
	_is_active = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
