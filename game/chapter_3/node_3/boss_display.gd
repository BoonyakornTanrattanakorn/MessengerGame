# BossDisplay.gd
extends Node2D

@onready var phase1_sprite = $Phase1Sprite
@onready var phase2_sprite = $Phase2Sprite
@onready var phase3_sprite = $Phase3Sprite

func _ready():
	show_phase(1)

func show_phase(phase: int):
	phase1_sprite.visible = (phase == 1)
	phase2_sprite.visible = (phase == 2)
	phase3_sprite.visible = (phase == 3)
	print("[Boss] Showing phase ", phase, " sprite")

func play_defeat():
	phase1_sprite.visible = false
	phase2_sprite.visible = false
	phase3_sprite.visible = false
	print("[Boss] Defeated!")
