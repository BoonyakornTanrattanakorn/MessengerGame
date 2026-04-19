extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	SaveManager.save_game()
	get_tree().change_scene_to_file("res://game/chapter_4/node_10/node_10.tscn")
