extends Area2D
class_name Trigger

@export var trigger_id: int = 0
@export var trigger_once: bool = true

var has_triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	if trigger_once and has_triggered:
		return

	has_triggered = true

	handle_trigger()

func handle_trigger() -> void:
	# for triggers reusability
	return
	
	
	# ScriptedObjects/ChapterGateNpc
	
func save():
	return {"has_triggered" : has_triggered}

func load_game(data):
	has_triggered = data.get("has_triggered", has_triggered)
