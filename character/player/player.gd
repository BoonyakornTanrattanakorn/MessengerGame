extends CharacterBody2D

var speed = 200.0  # speed in pixels/sec
var dash_speed = 500.0
var dash_duration = 0.15
var dash_cooldown = 0.5

var playerAttribute = "wind"

# Dash system
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var last_direction: Vector2 = Vector2.RIGHT  # Track last faced direction

var interact_with = ""
var current_dialog = 0
@onready var hud = $PlayerHUD  # or get_node path

@export var save_id = "player" 
@export var save_scope = "global" 

func _ready():
	add_to_group("savable")
	hud.skill_changed.connect(_on_skill_changed)
	# Set starting attribute from HUD
	playerAttribute = hud.get_current_skill()

func _on_skill_changed(attribute: String):
	playerAttribute = attribute
	print("Switched to: ", attribute)

func _physics_process(delta):
	var direction = Input.get_vector("left", "right", "up", "down")
	
	# Dialogue
	if(interact_with != ""):
		if(Input.is_action_just_pressed("interact")):
			DialogueManager.show_example_dialogue_balloon(
				load("res://dialogue/conversations/"+ interact_with + ".dialogue"), 
				"_"+str(current_dialog)
			)
	
	# Update last direction if there's input
	if direction.length() > 0:
		last_direction = direction.normalized()
	
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	
	# Handle dashing
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			# End dash
			is_dashing = false
			dash_cooldown_timer = dash_cooldown
		else:
			# During dash: move in dash direction at dash speed
			velocity = last_direction * dash_speed
			move_and_slide()
			return  # Skip rest of physics processing while dashing
	
	# Handle dash input (only if not on cooldown and not already dashing)
	if Input.is_action_just_pressed("minor magic") and dash_cooldown_timer <= 0 and not is_dashing and playerAttribute == "wind":
		# Start dash in last faced direction
		is_dashing = true
		dash_timer = dash_duration
		velocity = last_direction * dash_speed
	
	# Normal movement
	velocity = direction * speed
	move_and_slide()


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.has_method("can_interact"):
		interact_with = body.name	
		current_dialog = body.can_interact()
		print("Interactable")


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.has_method("can_interact"):
		interact_with = ""	
		print("Exited")
		
func save():
	return {
		"position" : {
			"x" : position.x,
			"y" : position.y
		},
		"playerAttribute" : playerAttribute
	}
	
func load_data(data):
	var pos = data.get("position", null)

	if pos:
		position = Vector2(pos["x"], pos["y"])

	playerAttribute = data.get("attribute", playerAttribute)
