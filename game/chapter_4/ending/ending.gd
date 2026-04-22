extends Node2D

@export var base_scroll_speed: float = 48.0
@export var fast_scroll_multiplier: float = 3.0
@export var auto_return_delay: float = 3.0

@onready var credits_text: Label = $CanvasLayer/UIRoot/CreditsText
@onready var skip_hint: Label = $CanvasLayer/UIRoot/SkipHint

var _is_rolling: bool = true
var _is_returning: bool = false

func _ready() -> void:
	skip_hint.visible = false
	credits_text.position.y = get_viewport_rect().size.y + 40.0

func _process(delta: float) -> void:
	if not _is_rolling:
		return

	var speed := base_scroll_speed
	if Input.is_action_pressed("ui_accept") or Input.is_action_pressed("ui_cancel"):
		speed *= fast_scroll_multiplier

	credits_text.position.y -= speed * delta

	if credits_text.position.y + credits_text.size.y < -40.0:
		_is_rolling = false
		skip_hint.visible = true
		_start_auto_return()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if _is_returning:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		_return_to_menu()
		return

	if event is InputEventKey and event.pressed:
		_return_to_menu()
		return

	if event is InputEventMouseButton and event.pressed:
		_return_to_menu()

func _start_auto_return() -> void:
	if _is_returning:
		return
	await get_tree().create_timer(auto_return_delay).timeout
	if _is_returning:
		return
	_return_to_menu()

func _return_to_menu() -> void:
	if _is_returning:
		return
	_is_returning = true
	get_tree().change_scene_to_file("res://ui/menu/main_menu.tscn")
