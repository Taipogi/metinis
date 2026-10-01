class_name ParallaxItem
extends Control

@export_group("Motion")
@export_range(0.0, 512.0, 0.5) var max_offset: float = 30.0
@export var invert_direction: bool = true
@export_range(0.1, 30.0, 0.1) var smooth_speed: float = 6.0

@export_group("Shadow")
@export_range(0.0, 128.0, 0.5) var shadow_max_offset: float = 6.0
@export var shadow_invert: bool = true
@export_range(0.1, 30.0, 0.1) var shadow_smooth_speed: float = 4.0


var _applied: Vector2 = Vector2.ZERO
var _shadow_drift: Vector2 = Vector2.ZERO
var _has_font_shadow := false
var _font_base := Vector2.ZERO
var _font_last := Vector2i.ZERO
var _shadow_boxes: Array[StyleBoxFlat] = []
var _shadow_box_bases: Array[Vector2] = []

const SHADOW_STATES = [&"normal", &"hover", &"pressed", &"disabled"]


func _ready() -> void:
	_capture_shadow_setup()

func _process(delta: float) -> void:
	var direction := -1.0 if invert_direction else 1.0
	var target: Vector2 = MouseParallax.offset * (max_offset * direction)

	var previous := _applied
	_applied = _applied.lerp(target, _weight(smooth_speed, delta))

	position += _applied - previous

	_process_shadow(delta)


func _process_shadow(delta: float) -> void:
	if not _has_font_shadow and _shadow_boxes.is_empty():
		return

	var direction := (-1.0 if invert_direction else 1.0) * (-1.0 if shadow_invert else 1.0)
	var target: Vector2 = MouseParallax.offset * (shadow_max_offset * direction)
	_shadow_drift = _shadow_drift.lerp(target, _weight(shadow_smooth_speed, delta))
	_apply_shadow_drift(_shadow_drift)

func set_layout_position(base_position: Vector2) -> void:
	position = base_position + _applied
	
func _capture_shadow_setup() -> void:
	if has_theme_color(&"font_shadow_color") \
		and has_theme_constant(&"shadow_offset_x") \
		and has_theme_constant(&"shadow_offset_y") \
		and get_theme_color(&"font_shadow_color").a > 0.0:

		_has_font_shadow = true
		_font_base = Vector2(
			get_theme_constant(&"shadow_offset_x"),
			get_theme_constant(&"shadow_offset_y"))
		_font_last = Vector2i(roundi(_font_base.x), roundi(_font_base.y))

	for state in SHADOW_STATES:
		if not has_theme_stylebox(state):
			continue
		var original := get_theme_stylebox(state) as StyleBoxFlat
		if original == null or original.shadow_size <= 0:
			continue
		var own := original.duplicate() as StyleBoxFlat
		add_theme_stylebox_override(state, own)
		_shadow_boxes.append(own)
		_shadow_box_bases.append(original.shadow_offset)


func _apply_shadow_drift(drift: Vector2) -> void:
	if _has_font_shadow:
		var total := _font_base + drift
		var rounded := Vector2i(roundi(total.x), roundi(total.y))
		if rounded != _font_last:
			_font_last = rounded
			add_theme_constant_override(&"shadow_offset_x", rounded.x)
			add_theme_constant_override(&"shadow_offset_y", rounded.y)

	for i in _shadow_boxes.size():
		var wanted := _shadow_box_bases[i] + drift
		if _shadow_boxes[i].shadow_offset != wanted:
			_shadow_boxes[i].shadow_offset = wanted
			queue_redraw()

func _weight(speed: float, delta: float) -> float:
	return 1.0 - exp(-speed * delta)
