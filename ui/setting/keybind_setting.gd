extends VBoxContainer

var waiting_action = null
var buttons = {}
var input_to_name = {
	"up": "Walk Up",
	"down": "Walk Down",
	"left": "Walk Left",
	"right": "Walk Right",
	"lesser_magic": "Lesser Magic",
	"greater_magic": "Greater Magic",
	"interact": "Interact",
	"use_item": "Use Item",
	"element_rotate_left": "Rotate Element Left",
	"element_rotate_right": "Rotate Element Right",
	"power_wheel": "Power Wheel",
	"item_rotate_left": "Rotate Item Left",
	"item_rotate_right": "Rotate Item Right",
	"pause_menu": "Pause Menu",
	"world_map": "World Map"
}

func _ready():
	create_input_buttons()

func create_input_buttons():
	var actions = InputMap.get_actions()

	var filtered_actions = []
	for action in actions:
		if not action.begins_with("ui_"):
			filtered_actions.append(action)

	for i in range(filtered_actions.size()):
		var action = filtered_actions[i]
		print(action)
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_top", 6)
		margin.add_theme_constant_override("margin_bottom", 6)

		var row = HBoxContainer.new()

		var label = Label.new()
		if(input_to_name.has(action)):
			label.text = input_to_name[action]
		else:
			label.text = action
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 28)

		var button = Button.new()
		button.set_meta("action", action)
		button.add_theme_font_size_override("font_size", 24)
		button.custom_minimum_size = Vector2(160, 32)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		row.add_child(label)
		row.add_child(button)

		margin.add_child(row)
		add_child(margin)

		buttons[action] = button
		button.pressed.connect(_on_button_pressed.bind(action))

		update_button_text(action)

		# Add separator line (except after last row)
		if i < filtered_actions.size() - 1:
			var sep = HSeparator.new()
			sep.modulate = Color(0.248, 0.248, 0.248, 1.0)
			add_child(sep)

func _on_button_pressed(action):
	if waiting_action != null:
		update_button_text(waiting_action)

	waiting_action = action
	buttons[action].text = "Press key..."

func _input(event):
	if waiting_action != null and event is InputEventKey and event.pressed:

		var new_event = InputEventKey.new()
		new_event.keycode = event.keycode
		new_event.shift_pressed = event.shift_pressed
		new_event.ctrl_pressed = event.ctrl_pressed
		new_event.alt_pressed = event.alt_pressed

		InputMap.action_erase_events(waiting_action)
		InputMap.action_add_event(waiting_action, new_event)

		update_button_text(waiting_action)
		waiting_action = null

func update_button_text(action):
	var events = InputMap.action_get_events(action)

	if events.size() > 0:
		var e = events[0]

		if e is InputEventKey:
			if e.keycode != 0:
				buttons[action].text = OS.get_keycode_string(e.keycode)
			else:
				buttons[action].text = OS.get_keycode_string(e.physical_keycode)
		else:
			buttons[action].text = e.as_text()
	else:
		buttons[action].text = "Unassigned"

func stop_listening():
	if waiting_action != null:
		update_button_text(waiting_action)
		waiting_action = null


func _on_back_button_pressed() -> void:
	pass # Replace with function body.
