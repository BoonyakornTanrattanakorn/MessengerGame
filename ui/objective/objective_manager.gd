extends Node

var hud_ref: Node = null

func register_hud(hud: Node) -> void:
	hud_ref = hud

func unregister_hud(hud: Node) -> void:
	if hud_ref == hud:
		hud_ref = null

func set_objective(text: String, prefix: String = "Objective: ") -> void:
	if hud_ref and hud_ref.has_method("set_objective_text"):
		hud_ref.set_objective_text(text, prefix)

func clear_objective() -> void:
	if hud_ref and hud_ref.has_method("clear_objective"):
		hud_ref.clear_objective()

func get_objective() -> String:
	if hud_ref and hud_ref.has_method("get_objective_text"):
		return hud_ref.get_objective_text()
	return ""
