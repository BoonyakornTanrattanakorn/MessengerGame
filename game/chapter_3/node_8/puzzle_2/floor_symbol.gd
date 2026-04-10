extends Area2D

signal symbol_stepped_on(symbol_id: int)

@export var symbol_id: int = 1
@export var activated_texture: Texture2D

@onready var _sprite: Sprite2D = $Sprite2D

var _is_active := false
var _original_texture: Texture2D
var _original_scale: Vector2

func _ready() -> void:
	hide()
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
	if _sprite and _original_texture == null:
		_original_texture = _sprite.texture
		_original_scale = _sprite.scale
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

func deactivate() -> void:
	_is_active = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

func set_activated_visual() -> void:
	if _sprite and activated_texture and _original_texture:
		var orig_size := _original_texture.get_size()
		var act_size := activated_texture.get_size()
		if act_size.x > 0 and act_size.y > 0:
			_sprite.scale = _original_scale * (orig_size / act_size)
		_sprite.texture = activated_texture

func reset_visual() -> void:
	if _sprite and _original_texture:
		_sprite.texture = _original_texture
		_sprite.scale = _original_scale
