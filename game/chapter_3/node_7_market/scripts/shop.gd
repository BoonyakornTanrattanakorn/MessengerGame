class_name ShopNPC
extends Node2D

@export var player_node_name: String = "Player"
@export var dialogue_resource: DialogueResource
@onready var interaction_area: Area2D = $Area2D
@onready var shop_ui: CanvasLayer = $ShopUI
@onready var shop_container: VBoxContainer = $ShopUI/PanelContainer/VBoxContainer

var player_in_range := false
var selected_index: int = 0
var _item_labels: Array[Label] = []

const SHOP_ITEMS = [
	{ "label": "Health Potion", "item": "potion", "cost": 10 },
]

func _ready() -> void:
	shop_ui.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	shop_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	call_deferred("_build_shop_ui")

func _on_body_entered(body: Node) -> void:
	if body.name == player_node_name:
		player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.name == player_node_name:
		player_in_range = false
		_close_shop()

func _unhandled_input(event: InputEvent) -> void:
	if not shop_ui.visible:
		if player_in_range and event.is_action_pressed("interact"):
			_open_shop()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_up"):
		selected_index = max(0, selected_index - 1)
		_refresh_items()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		selected_index = min(SHOP_ITEMS.size(), selected_index + 1)
		_refresh_items()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		_confirm_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_close_shop()
		get_viewport().set_input_as_handled()

func _open_shop() -> void:
	if dialogue_resource:
		await _show_shopkeeper_line()
	selected_index = 0
	shop_ui.visible = true
	get_tree().paused = true
	_refresh_gem_label()
	_refresh_items()

func _show_shopkeeper_line() -> void:
	var title := "shop_repeat" if Node7State.visited_shop else "shop_first"
	Node7State.visited_shop = true
	DialogueManager.show_dialogue_balloon(dialogue_resource, title)
	await DialogueManager.dialogue_ended

func _close_shop() -> void:
	shop_ui.visible = false
	get_tree().paused = false

func _confirm_selection() -> void:
	if selected_index == SHOP_ITEMS.size():
		_close_shop()
		return
	_buy(SHOP_ITEMS[selected_index])

func _build_shop_ui() -> void:
	var panel = $ShopUI/PanelContainer
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0

	var gem_label = Label.new()
	gem_label.name = "CrystalLabel"
	shop_container.add_child(gem_label)

	for item_data in SHOP_ITEMS:
		var lbl = Label.new()
		lbl.custom_minimum_size = Vector2(250, 36)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		shop_container.add_child(lbl)
		_item_labels.append(lbl)

	var close_lbl = Label.new()
	close_lbl.custom_minimum_size = Vector2(250, 36)
	close_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shop_container.add_child(close_lbl)
	_item_labels.append(close_lbl)

	await get_tree().process_frame
	var viewport_size = get_viewport().get_visible_rect().size
	panel.position = (viewport_size - panel.size) / 2.0

func _refresh_gem_label() -> void:
	var label = shop_container.get_node_or_null("CrystalLabel")
	if label:
		label.text = "Gems: %d" % GameState.minigame_gems

func _refresh_items() -> void:
	for i in SHOP_ITEMS.size():
		var prefix = "> " if i == selected_index else "   "
		_item_labels[i].text = "%s%s  (%d gems)" % [prefix, SHOP_ITEMS[i]["label"], SHOP_ITEMS[i]["cost"]]
	var close_i = SHOP_ITEMS.size()
	_item_labels[close_i].text = "> Close" if close_i == selected_index else "   Close"

func _buy(item_data: Dictionary) -> void:
	if GameState.minigame_gems < item_data["cost"]:
		print("Not enough gems!")
		return
	var player = get_tree().root.find_child(player_node_name, true, false)
	if not player:
		return
	GameState.minigame_gems -= item_data["cost"]
	player.add_item(item_data["item"], 1)
	_refresh_gem_label()
	_refresh_items()
	print("Bought: ", item_data["label"])
