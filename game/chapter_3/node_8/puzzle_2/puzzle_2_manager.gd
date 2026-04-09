extends Node2D

signal puzzle_completed

# The correct order to step on symbols: e.g. [2, 1, 3] means step on symbol_id 2 first, then 1, then 3.
# Set this in the editor to match your hieroglyph hints.
@export var correct_sequence: Array[int] = [1, 2, 3]

@export var exit_warp: Node2D

var _player_sequence: Array[int] = []
var _sand_covers: Array[Node2D] = []
var _symbols: Array[Node2D] = []
var _is_solved := false

func _ready() -> void:
	await get_tree().process_frame

	for child in get_children():
		if child.is_in_group("sand_cover"):
			_sand_covers.append(child)
		if child.is_in_group("floor_symbol"):
			_symbols.append(child)
			child.symbol_stepped_on.connect(_on_symbol_stepped_on)

	_set_symbols_active(false)
	_connect_sand_covers()

	if exit_warp:
		exit_warp.hide()

func _connect_sand_covers() -> void:
	for cover in _sand_covers:
		if cover.has_signal("tree_exited"):
			pass
		# When all covers are cleared, activate symbols
		# Each cover's clear_sand fires; we poll in process
	# Instead, check via a timer each frame
	set_process(true)

func _process(_delta: float) -> void:
	if _is_solved:
		return
	var all_cleared := _sand_covers.all(func(c): return not c.visible)
	if all_cleared and _sand_covers.size() > 0:
		_set_symbols_active(true)
		set_process(false)

func _set_symbols_active(active: bool) -> void:
	for sym in _symbols:
		if active:
			sym.activate()
		else:
			sym.deactivate()

func _on_symbol_stepped_on(symbol_id: int) -> void:
	if _is_solved:
		return

	_player_sequence.append(symbol_id)
	var step := _player_sequence.size() - 1

	if _player_sequence[step] != correct_sequence[step]:
		_reset_puzzle()
		return

	if _player_sequence.size() == correct_sequence.size():
		_on_puzzle_solved()

func _reset_puzzle() -> void:
	_player_sequence.clear()
	for cover in _sand_covers:
		if cover.has_method("reset_sand"):
			cover.reset_sand()
	_set_symbols_active(false)
	set_process(true)

func _on_puzzle_solved() -> void:
	_is_solved = true
	puzzle_completed.emit()
	Chap3Node8State.complete_puzzle(2)
	if exit_warp:
		exit_warp.show()
