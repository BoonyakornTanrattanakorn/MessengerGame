# blast_skill.gd
extends Node2D

signal charge_changed(current_charge)

const MAX_CHARGE = 20
const BLAST_RADIUS = 20.0

@onready var indicator = $SkillIndicator
@onready var circle = $SkillIndicator/RadiusCircle  # ← your circle sprite node name
@onready var blast_area = $BlastArea
@onready var blast_shape = $BlastArea/CollisionShape2D

var current_charge = 3
var skill_enabled = false

func _ready():
	indicator.visible = false
	circle.visible = false  # ← hidden by default
	(blast_shape.shape as CircleShape2D).radius = BLAST_RADIUS
	blast_area.monitoring = false

func enable():
	skill_enabled = true
	indicator.visible = true

func disable():
	skill_enabled = false
	indicator.visible = false
	circle.visible = false

func _process(_delta):
	if not skill_enabled:
		return
	var mouse_pos = get_global_mouse_position()
	indicator.global_position = mouse_pos
	blast_area.global_position = mouse_pos

func _unhandled_input(event):
	if not skill_enabled:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if current_charge > 0:  # ← check charge first
				circle.visible = true
				blast(get_global_mouse_position())
		else:
			circle.visible = false  # always hide on release

func blast(pos: Vector2):
	current_charge -= 1
	emit_signal("charge_changed", current_charge)
	
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = BLAST_RADIUS
	query.shape = shape
	query.transform = Transform2D(0, pos)
	query.collide_with_bodies = true
	query.collide_with_areas = true
	
	var results = space.intersect_shape(query, 32)
	for result in results:
		var obj = result.collider
		if obj.is_in_group("breakable"):
			if obj.has_method("take_hit"):
				obj.take_hit()          # ← multi-hit breakable
			elif obj.has_method("break_obstacle"):
				obj.break_obstacle() 

func add_charge(amount: int = 1):
	current_charge = min(current_charge + amount, MAX_CHARGE)
	emit_signal("charge_changed", current_charge)
