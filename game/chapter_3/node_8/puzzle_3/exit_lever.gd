extends Node2D

signal lever_pulled

@export var is_pulled := false

func can_interact() -> int:
	return 1 if not is_pulled else 0

func activate() -> void:
	if is_pulled:
		return
	is_pulled = true
	lever_pulled.emit()
