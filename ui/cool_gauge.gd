extends HBoxContainer

@onready var segment_bar = $SegmentBar

const SEG_COUNT = 3
const MIDDLE_WIDTH = 32
const END_WIDTH = 38

const COLOR_EMPTY    = Color(0.02, 0.05, 0.15)
const COLOR_LEVEL1   = Color(0.2,  0.5,  0.9)
const COLOR_LEVEL2   = Color(0.1,  0.3,  1.0)
const COLOR_LEVEL3   = Color(0.0,  0.6,  1.0)
const COLOR_CHARGING = Color(0.5,  0.8,  1.0)  # bright pulse while charging

var cool_gauge_value: int = 0
var segments: Array = []
var max_hp: int = 3

func _ready():
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_build_segments()

func set_max_hp(hp: int):
	max_hp = hp
	_build_segments()

func _build_segments():
	for child in segment_bar.get_children():
		child.queue_free()
	segments.clear()

	var total_width = (max_hp - 1) * MIDDLE_WIDTH + END_WIDTH
	var each_w = float(total_width - (SEG_COUNT - 1) * 3) / SEG_COUNT

	for i in SEG_COUNT:
		var seg = ColorRect.new()
		seg.custom_minimum_size = Vector2(each_w, 12)
		seg.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		seg.color = COLOR_EMPTY
		segment_bar.add_child(seg)
		segments.append(seg)

func update_cool(value: int):
	cool_gauge_value = value
	for i in SEG_COUNT:
		if i < value:
			segments[i].color = _get_level_color(i)
		else:
			segments[i].color = COLOR_EMPTY

func _get_level_color(index: int) -> Color:
	match index:
		0: return COLOR_LEVEL1
		1: return COLOR_LEVEL2
		2: return COLOR_LEVEL3
	return COLOR_LEVEL1

func update_cool_preview(preview_value: int):
	for i in SEG_COUNT:
		if i < cool_gauge_value:
			# Already filled — show normal color
			segments[i].color = _get_level_color(i)
		elif i < preview_value:
			# Preview segments — show bright pulsing color
			segments[i].color = COLOR_CHARGING
		else:
			segments[i].color = COLOR_EMPTY
