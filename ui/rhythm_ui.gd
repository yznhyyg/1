extends RefCounted

const ACCENT := Color("#9C87FF")
const CYAN := Color("#66E7DA")
const MUTED := Color("#9BA6BE")
const Backdrop = preload("res://ui/backdrop.gd")

static func box(fill: Color, edge: Color, radius: int = 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 22
	theme.set_color("font_color", "Label", Color("#F2F3FF"))
	for state in ["normal", "hover", "pressed", "disabled"]:
		var fill := Color("#192238")
		var edge := Color("#303C57")
		if state == "hover":
			fill = Color("#28324D")
			edge = ACCENT
		elif state == "pressed":
			fill = Color("#353253")
		elif state == "disabled":
			fill = Color("#131A29")
		theme.set_stylebox(state, "Button", box(fill, edge))
	theme.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), CYAN))
	theme.set_color("font_color", "Button", Color("#F2F3FF"))
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", MUTED)
	theme.set_stylebox("normal", "LineEdit", box(Color("#0C1322"), Color("#35405B"), 12))
	theme.set_stylebox("focus", "LineEdit", box(Color(0, 0, 0, 0), CYAN, 12))
	theme.set_color("font_placeholder_color", "LineEdit", MUTED)
	theme.set_color("caret_color", "LineEdit", CYAN)
	theme.set_stylebox("panel", "Panel", box(Color("#131C2E"), Color("#303C57"), 24))
	var rail := box(Color("#29354B"), Color("#29354B"), 3)
	rail.content_margin_top = 3
	rail.content_margin_bottom = 3
	theme.set_stylebox("slider", "HSlider", rail)
	theme.set_stylebox("grabber_area", "HSlider", box(ACCENT, ACCENT, 3))
	theme.set_stylebox("grabber_area_highlight", "HSlider", box(CYAN, CYAN, 3))
	return theme

static func setup(root: Control, minimal_background: bool = false) -> void:
	root.theme = make_theme()
	var background := Backdrop.new()
	background.minimal = minimal_background
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(background)
	root.move_child(background, 0)

static func label(root: Node, text: String, rect: Rect2, font_size: int = 22, color: Color = Color.WHITE) -> Label:
	var item := Label.new()
	item.text = text
	item.position = rect.position
	item.size = rect.size
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", color)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(item)
	return item

static func card(root: Node, rect: Rect2) -> Panel:
	var item := Panel.new()
	item.position = rect.position
	item.size = rect.size
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(item)
	return item

static func primary(button: Button) -> void:
	button.add_theme_stylebox_override("normal", box(Color("#7960E8"), ACCENT))
	button.add_theme_stylebox_override("hover", box(Color("#9177FF"), Color("#C3B5FF")))
	button.add_theme_stylebox_override("pressed", box(Color("#624AC7"), ACCENT))
	button.add_theme_font_size_override("font_size", 24)

static func reveal(root: Control) -> void:
	root.modulate.a = 0.0
	root.create_tween().tween_property(root, "modulate:a", 1.0, 0.22)
