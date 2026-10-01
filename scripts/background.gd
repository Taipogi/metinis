extends TextureRect

@export var max_offset: float = 30

@export var smooth_speed: float = 6

@export var invert_direction: bool = true

var base_position: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	get_viewport().size_changed.connect(_update_layout)
	_update_layout()

func _update_layout() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	if vp_size == Vector2.ZERO:
		return
	
	size = vp_size + Vector2(max_offset * 2, max_offset * 2)
	
	base_position = Vector2(-max_offset, -max_offset)
	position = base_position

func _process(delta: float) -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	if vp_size == Vector2.ZERO:
		return
	
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	
	var center: Vector2 = vp_size * 0.5
	var normalized_mouse: Vector2 = (mouse_pos - center) / center
	
	normalized_mouse = normalized_mouse.clamp(Vector2(-1, -1), Vector2(1, 1))
	
	var direction_multiplier: float = -1 if invert_direction else 1
	var offset: Vector2 = normalized_mouse * max_offset * direction_multiplier
	target_position = base_position + offset

	position = position.lerp(target_position, smooth_speed * delta)
