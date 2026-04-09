extends Area2D

signal symbol_stepped_on(symbol_id: int)

# Set this in the editor to match the correct sequence order (1, 2, 3, ...)
@export var symbol_id: int = 1

var _is_active := false

func _ready() -> void:
	hide()
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not _is_active:
		return
	if body.name == "Player":
		symbol_stepped_on.emit(symbol_id)

func activate() -> void:
	_is_active = true

func deactivate() -> void:
	_is_active = false
