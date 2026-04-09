extends Area2D

signal plate_activated(plate: Node2D)
signal plate_deactivated(plate: Node2D)

@export var plate_id: String = "plate_a"
@export var is_correct_plate: bool = true

var is_activated := false
var _block_on_plate: Node2D = null

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("sand_block"):
		_activate(body)

func _on_body_exited(body: Node) -> void:
	if body == _block_on_plate:
		_deactivate()

func _on_area_entered(_area: Area2D) -> void:
	pass

func _on_area_exited(_area: Area2D) -> void:
	pass

func _activate(block: Node2D) -> void:
	if is_activated:
		return
	is_activated = true
	_block_on_plate = block
	if block.has_method("set_on_plate"):
		block.set_on_plate(self)
	plate_activated.emit(self)

func _deactivate() -> void:
	if not is_activated:
		return
	is_activated = false
	if _block_on_plate and _block_on_plate.has_method("clear_plate"):
		_block_on_plate.clear_plate()
	_block_on_plate = null
	plate_deactivated.emit(self)
