extends Area2D

# Covers a floor symbol. When hit by a wind projectile, it fades and hides.
@export var symbol_node: Node2D

var _is_cleared := false

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if _is_cleared:
		return
	if area.is_in_group("wind_wave"):
		clear_sand()

func clear_sand() -> void:
	if _is_cleared:
		return
	_is_cleared = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): hide())
	if symbol_node:
		symbol_node.show()

func reset_sand() -> void:
	_is_cleared = false
	modulate.a = 1.0
	show()
	if symbol_node:
		symbol_node.hide()
