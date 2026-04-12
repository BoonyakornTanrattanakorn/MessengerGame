extends Area2D

@export var player_node_name: String = "Player"
@export var fragment_id: String = ""
@export var item_name: String = ""
@export var item_amount: int = 1
@export var start_title: String = ""
@export var dialogue_resource: DialogueResource

@onready var prompt_label: Label = $PromptLabel

var player_in_range: bool = false
var is_talking: bool = false

func _ready() -> void:
	prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range:
		return
	if is_talking:
		return
	if event.is_action_pressed("interact"):
		read_paper()

func read_paper() -> void:
	if dialogue_resource == null:
		push_warning("Paper dialogue_resource is not assigned.")
		return
	if start_title == "":
		push_warning("Paper start_title is empty.")
		return

	is_talking = true
	prompt_label.visible = false

	var is_new_fragment := fragment_id != "" and fragment_id not in PuzzleState.found_fragments
	PuzzleState.collect_fragment(fragment_id)
	if is_new_fragment:
		_grant_inventory_item()
	_memorize_player_keywords_from_dialogue()
	DialogueManager.show_dialogue_balloon(dialogue_resource, start_title)

func _grant_inventory_item() -> void:
	var player := get_tree().root.find_child(player_node_name, true, false)
	if player == null or not player.has_method("add_item"):
		return

	var pickup_item_name := item_name.strip_edges()
	if pickup_item_name == "":
		pickup_item_name = fragment_id if fragment_id != "" else "torn_paper"

	player.add_item(pickup_item_name, item_amount)

func _memorize_player_keywords_from_dialogue() -> void:
	var dialogue_path := dialogue_resource.resource_path
	if dialogue_path.is_empty():
		return

	var torn_note_index := _get_torn_note_index()

	var file := FileAccess.open(dialogue_path, FileAccess.READ)
	if file == null:
		return

	var quote_regex := RegEx.create_from_string("\"([^\"]+)\"")
	var in_target_title := false

	while not file.eof_reached():
		var line := file.get_line().strip_edges()

		if line.begins_with("~ "):
			in_target_title = line.substr(2).strip_edges() == start_title
			continue

		if not in_target_title:
			continue

		if not line.begins_with("player:"):
			continue

		for match in quote_regex.search_all(line):
			var keyword := match.get_string(1).strip_edges()
			if not keyword.is_empty():
				ObjectiveManager.memorize_keyword(keyword, torn_note_index)

func _get_torn_note_index() -> int:
	var match_regex := RegEx.create_from_string("^paper_(\\d+)$")
	var match := match_regex.search(start_title.strip_edges().to_lower())
	if match == null:
		return -1
	return int(match.get_string(1))

func _on_body_entered(body: Node) -> void:
	if body.name == player_node_name:
		player_in_range = true
		if not is_talking:
			prompt_label.text = "Read"
			prompt_label.visible = true

func _on_body_exited(body: Node) -> void:
	if body.name == player_node_name:
		player_in_range = false
		prompt_label.visible = false

func _on_dialogue_ended(_resource: Resource) -> void:
	is_talking = false
	if player_in_range:
		prompt_label.text = "Read"
		prompt_label.visible = true

func _enter_tree() -> void:
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _exit_tree() -> void:
	if DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.disconnect(_on_dialogue_ended)
