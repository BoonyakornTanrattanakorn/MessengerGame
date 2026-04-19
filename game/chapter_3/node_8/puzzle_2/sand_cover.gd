extends Area2D

# Covers a floor symbol. When hit by a wind projectile, it fades and hides.
# symbol_node is auto-detected from sibling with floor_symbol group - no manual wiring needed.
@export var symbol_node: Node2D

var _is_cleared := false

func _ready() -> void:
	collision_mask |= 4  # include wind's collision layer (layer 3)
	area_entered.connect(_on_area_entered)
	# Auto-find the sibling FloorSymbol if export wasn't set
	if not symbol_node:
		for sibling in get_parent().get_children():
			if sibling != self and sibling.is_in_group("floor_symbol"):
				symbol_node = sibling
				break

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
	else:
		push_warning("SandCover: symbol_node is null on " + name)

func reset_sand() -> void:
	_is_cleared = false
	modulate.a = 1.0
	show()
	if symbol_node:
		symbol_node.hide()
