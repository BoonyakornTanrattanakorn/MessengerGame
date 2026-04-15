extends StaticBody2D

@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("quest_blocker")
	update_blocker()

func update_blocker() -> void:
	if Node7State.sandmonster_quest_accepted:
		collision.disabled = true   
		visible = false             
	else:
		collision.disabled = false  
		visible = true
