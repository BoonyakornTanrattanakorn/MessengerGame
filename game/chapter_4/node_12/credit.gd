extends Node2D

@onready var credit: Node2D = $"."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var area = $"Show Area"
	area.body_entered.connect(_on_area_body_entered)
	area.body_exited.connect(_on_area_body_exited)
	# Hide credit by default
	credit.hide()

# Called when a body enters the Show Area
func _on_area_body_entered(body):
	if body.name == "Player":
		_show_credit()

# Called when a body exits the Show Area
func _on_area_body_exited(body):
	if body.name == "Player":
		_hide_credit()

func _show_credit() -> void:
	credit.modulate.a = 0.0
	credit.show()
	var tween = create_tween()
	tween.tween_property(credit, "modulate:a", 1.0, 1.0)
	await tween.finished

func _hide_credit() -> void:
	var tween = create_tween()
	tween.tween_property(credit, "modulate:a", 0.0, 1.0)
	await tween.finished
	credit.hide()
	credit.queue_free()
