extends CharacterBody2D

var current_dialog = Global.current_enemy_dialog
 
func _physics_process(delta: float) -> void:
	$AnimatedSprite2D.play("default")
	$AnimatedSprite2D.flip_h = true	


func can_interact():
	return current_dialog
