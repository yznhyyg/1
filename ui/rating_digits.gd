extends Label

## Dynamic rating numerals using the C-style 0–9 atlas.
## The label text stays available to the rating logic and tests; each
## character is rendered from the matching atlas cell at runtime.

const DIGIT_ATLAS = preload("res://assets/branding/thetale_numbers_c.png")
const MAIN_COLOR := Color("#F4F5FF")
const EDGE_COLOR := Color(0.62, 0.55, 1.0, 0.32)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_color_override("font_color", Color(0, 0, 0, 0))
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var value := text
	if value.is_empty():
		return

	var glyph_count: int = value.length()
	var gap := 3.5
	var glyph_width := 34.0
	var decimal_width := 11.0
	var glyph_height := 62.0
	var total_width := 0.0
	for character in value:
		total_width += decimal_width if character == "." else glyph_width
	if glyph_count > 1:
		total_width += float(glyph_count - 1) * gap
	var scale_factor: float = minf(1.0, minf(size.x / maxf(total_width, 1.0), size.y / glyph_height))
	var width := glyph_width * scale_factor
	var height := glyph_height * scale_factor
	var dot_width := decimal_width * scale_factor
	var spacing := gap * scale_factor
	var x: float = (size.x - (total_width * scale_factor)) * 0.5
	var y: float = (size.y - height) * 0.5
	var cell_width := float(DIGIT_ATLAS.get_width()) / 10.0

	for character in value:
		if character == ".":
			draw_circle(Vector2(x + dot_width * 0.5, y + height - 5.0 * scale_factor), 3.0 * scale_factor, MAIN_COLOR)
			x += dot_width + spacing
			continue
		if character >= "0" and character <= "9":
			var index := int(character)
			var source := Rect2(float(index) * cell_width, 0.0, cell_width, float(DIGIT_ATLAS.get_height()))
			var destination := Rect2(x, y, width, height)
			var shadow_destination := destination
			shadow_destination.position += Vector2(2.0 * scale_factor, 2.0 * scale_factor)
			draw_texture_rect_region(DIGIT_ATLAS, shadow_destination, source, EDGE_COLOR)
			draw_texture_rect_region(DIGIT_ATLAS, destination, source, MAIN_COLOR)
		x += width + spacing
