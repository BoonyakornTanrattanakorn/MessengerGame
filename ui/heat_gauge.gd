extends HBoxContainer

@onready var segment_bar = $SegmentBar

const SEG_COUNT = 10
const SEG_GAP = 3
const MIDDLE_WIDTH = 32
const END_WIDTH = 38

const COLOR_EMPTY    = Color(0.12, 0.05, 0.02)
const COLOR_COOL     = Color(0.55, 0.18, 0.02)
const COLOR_WARM     = Color(0.85, 0.35, 0.02)
const COLOR_HOT      = Color(0.95, 0.15, 0.0)
const COLOR_CRITICAL = Color(1.0,  0.05, 0.0)

var segments: Array = []
var current_heat: float = 0.0
var max_hp: int = 3

func _ready():
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_build_segments()

func set_max_hp(hp: int):
	max_hp = hp
	_build_segments()

func _build_segments():
	# Clear old segments
	for child in segment_bar.get_children():
		child.queue_free()
	segments.clear()

	# Calculate total HP bar width
	# (max_hp - 1) middle segments + 1 end segment
	var total_width = (max_hp - 1) * MIDDLE_WIDTH + END_WIDTH

	# Spread SEG_COUNT segments across that exact width
	var each_w = float(total_width - (SEG_COUNT - 1) * SEG_GAP) / SEG_COUNT

	for i in SEG_COUNT:
		var seg = ColorRect.new()
		seg.custom_minimum_size = Vector2(each_w, 10)
		seg.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		seg.color = COLOR_EMPTY
		segment_bar.add_child(seg)
		segments.append(seg)

	update_heat(current_heat)

func update_heat(value: float):
	current_heat = clamp(value, 0.0, 100.0)
	var ratio = current_heat / 100.0
	for i in segments.size():
		var seg_ratio_start = float(i) / SEG_COUNT
		var seg_ratio_end   = float(i + 1) / SEG_COUNT
		if ratio <= seg_ratio_start:
			segments[i].color = COLOR_EMPTY
		elif ratio >= seg_ratio_end:
			segments[i].color = _get_seg_color(seg_ratio_end)
		else:
			segments[i].color = _get_seg_color(seg_ratio_start + 0.05)

func _get_seg_color(position: float) -> Color:
	if position < 0.4:
		return COLOR_COOL
	elif position < 0.65:
		return COLOR_WARM
	elif position < 0.85:
		return COLOR_HOT
	else:
		return COLOR_CRITICAL
