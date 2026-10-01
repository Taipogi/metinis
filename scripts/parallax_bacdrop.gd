class_name ParallaxBackdrop
extends ParallaxItem

func _ready() -> void:
	super()
	get_viewport().size_changed.connect(_update_layout)
	_update_layout()


func _update_layout() -> void:
	var screen := get_viewport_rect().size
	if screen.x < 2.0 or screen.y < 2.0:
		return

	var margin := Vector2(max_offset, max_offset)
	size = screen + margin * 2.0
	set_layout_position(-margin)
