extends Label

## Plain white rating text. The value remains a normal Label so it can update
## freely without an image atlas or segmented numerals.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_color_override("font_color", Color("#FFFFFF"))
	add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.28))
	add_theme_constant_override("shadow_offset_x", 1)
	add_theme_constant_override("shadow_offset_y", 2)
