class_name ShopNPC
extends Node2D

@export var player_node_name: String = "Player"
@export var dialogue_resource: DialogueResource
@onready var interaction_area: Area2D = $Area2D
@onready var shop_ui: CanvasLayer = $ShopUI
@onready var shop_container: VBoxContainer = $ShopUI/PanelContainer/VBoxContainer

var player_in_range := false

const SHOP_ITEMS = [
	{ "label": "Health Potion",  "item": "potion",     "cost": 2 },
	{ "label": "Weak Gun",       "item": "weak_gun",   "cost": 3 },
	{ "label": "Strong Gun",     "item": "strong_gun", "cost": 6 },
]

func _ready() -> void:
	shop_ui.visible = false
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	call_deferred("_build_shop_ui")

func _on_body_entered(body: Node) -> void:
	if body.name == player_node_name:
		player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.name == player_node_name:
		player_in_range = false
		shop_ui.visible = false
		get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and shop_ui.visible:
		_close_shop()
		get_viewport().set_input_as_handled()
		return
	if not player_in_range or shop_ui.visible:
		return
	if event.is_action_pressed("interact"):
		_open_shop()

func _open_shop() -> void:
	if dialogue_resource:
		await _show_shopkeeper_line()
	shop_ui.visible = true
	get_tree().paused = true
	_refresh_crystal_label()

func _show_shopkeeper_line() -> void:
	var title := "shop_repeat" if Node7State.visited_shop else "shop_first"
	Node7State.visited_shop = true
	DialogueManager.show_dialogue_balloon(dialogue_resource, title)
	await DialogueManager.dialogue_ended

func _close_shop() -> void:
	shop_ui.visible = false
	get_tree().paused = false

func _build_shop_ui() -> void:
	var crystal_label = Label.new()
	crystal_label.name = "CrystalLabel"
	shop_container.add_child(crystal_label)

	for item_data in SHOP_ITEMS:
		var btn = Button.new()
		btn.text = "%s  (%d crystals)" % [item_data["label"], item_data["cost"]]
		btn.pressed.connect(_on_buy_pressed.bind(item_data))
		shop_container.add_child(btn)

	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(_close_shop)
	shop_container.add_child(close_btn)

func _refresh_crystal_label() -> void:
	var player = get_tree().root.find_child(player_node_name, true, false)
	var crystals = player.inventory.get("desert_crystal", 0) if player else 0
	var label = shop_container.get_node_or_null("CrystalLabel")
	if label:
		label.text = "Desert Crystals: %d" % crystals

func _on_buy_pressed(item_data: Dictionary) -> void:
	var player = get_tree().root.find_child(player_node_name, true, false)
	if not player:
		return
	var crystals = player.inventory.get("desert_crystal", 0)
	if crystals < item_data["cost"]:
		print("Not enough crystals!")
		return
	player.inventory["desert_crystal"] -= item_data["cost"]
	player.add_item(item_data["item"], 1)
	_refresh_crystal_label()
	print("Bought: ", item_data["label"])
