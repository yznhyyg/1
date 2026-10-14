extends RefCounted

const UI = preload("res://ui/rhythm_ui.gd")

static func title(root: Node, text: String, rect: Rect2, font_size: int = 64) -> Label:
	var item := UI.label(root, text, rect, font_size, Color("#F4F5FF"))
	item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item.add_theme_color_override("font_outline_color", Color("#111A31"))
	item.add_theme_color_override("font_shadow_color", Color(0.40, 0.90, 0.85, 0.34))
	item.add_theme_constant_override("outline_size", 5)
	item.add_theme_constant_override("shadow_offset_x", 3)
	item.add_theme_constant_override("shadow_offset_y", 4)
	return item

static func accent_line(root: Node, rect: Rect2) -> ColorRect:
	var line := ColorRect.new()
	line.position = rect.position
	line.size = rect.size
	line.color = Color("#66E7DA")
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(line)
	return line
