extends CharacterBody2D

var speed = 240.0
var interact_with = null
var last_direction: Vector2 = Vector2.RIGHT

@onready var animated_sprite = $AnimatedSprite2D
@onready var fairy_camera = $FairyCamera

func activate_camera():
	fairy_camera.enabled = true

func deactivate_camera():
	fairy_camera.enabled = false

func move(direction: Vector2, delta: float):
	velocity = direction * speed
	move_and_slide()
	if direction.length() > 0.1:
		last_direction = direction.normalized()
	_update_animation(direction)

func _update_animation(direction: Vector2):
	var moving = direction.length() > 0.1
	var prefix = "walk " if moving else "idle "
	var suffix = _facing_suffix(last_direction)
	var anim = prefix + suffix
	if animated_sprite.animation != anim:
		animated_sprite.play(anim)

func _facing_suffix(dir: Vector2) -> String:
	if abs(dir.x) >= abs(dir.y):
		return "right" if dir.x > 0 else "left"
	else:
		return "right" if last_direction.x >= 0 else "left"

func try_interact():
	if interact_with == null:
		print("[Fairy] No interactable nearby")
		return
	print("[Fairy] Interacting with: ", interact_with.name)
	
	var target = interact_with
	# If interact_with has no activate, try its parent
	if not target.has_method("activate") and target.get_parent().has_method("activate"):
		target = target.get_parent()
		print("[Fairy] Forwarding to parent: ", target.name)
	
	if target.has_method("activate"):
		target.activate()
	elif target.has_method("can_interact"):
		var dialogue_path = "res://dialogue/conversations/" + target.name + ".dialogue"
		if ResourceLoader.exists(dialogue_path):
			DialogueManager.show_dialogue_balloon(load(dialogue_path), "_0")
		else:
			print("[Fairy] No dialogue file at: ", dialogue_path)
	else:
		print("[Fairy] Target has no interact method")

func _on_interaction_area_body_entered(body: Node2D):
	print("[Fairy] Body entered: ", body.name, 
		  " | can_interact: ", body.has_method("can_interact"),
		  " | has no_interact meta: ", body.has_meta("no_interact"))
	if body.has_method("can_interact"):
		if body.has_meta("no_interact"):
			return
		interact_with = body
		print("[Fairy] Set interact_with to body: ", body.name)

func _on_interaction_area_body_exited(body: Node2D):
	if body == interact_with:
		interact_with = null
		print("[Fairy] Cleared interact_with (body exited): ", body.name)

func _on_interaction_area_area_entered(area: Area2D):
	print("[Fairy] Area entered: ", area.name,
		  " | can_interact: ", area.has_method("can_interact"),
		  " | has no_interact meta: ", area.has_meta("no_interact"))
	if area.has_method("can_interact"):
		if area.has_meta("no_interact"):
			return
		interact_with = area
		print("[Fairy] Set interact_with to area: ", area.name)

func _on_interaction_area_area_exited(area: Area2D):
	if area == interact_with:
		interact_with = null
		print("[Fairy] Cleared interact_with (area exited): ", area.name)

func _ready():
	add_to_group("water_fairy")
	print("[Fairy] Ready")
	var area = $InteractionArea
	if area == null:
		print("[Fairy] ERROR: InteractionArea not found!")
		return
	print("[Fairy] InteractionArea found, connecting signals")
	area.body_entered.connect(_on_interaction_area_body_entered)
	area.body_exited.connect(_on_interaction_area_body_exited)
	area.area_entered.connect(_on_interaction_area_area_entered)
	area.area_exited.connect(_on_interaction_area_area_exited)
	print("[Fairy] Signals connected")
