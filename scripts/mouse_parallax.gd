extends Node

var offset: Vector2 = Vector2.ZERO

signal offset_changed(new_offset: Vector2)


func _process(_delta: float) -> void:
	var viewport := get_viewport()
	var size := viewport.get_visible_rect().size
	if size.x < 2.0 or size.y < 2.0:
		return

	var next := (viewport.get_mouse_position() - size * 0.5) / (size * 0.5)
	next = next.clamp(-Vector2.ONE, Vector2.ONE)
	if next != offset:
		offset = next
		offset_changed.emit(offset)
