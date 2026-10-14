extends Label

## Dynamic rating numerals using the C-style 0–9 atlas.
## The label text stays available to the rating logic and tests; each
## character is rendered from the matching atlas cell at runtime.

const DIGIT_ATLAS = preload("res://assets/branding/thetale_numbers_c.png")
const MAIN_COLOR := Color("#FF75BC")
const EDGE_COLOR := Color(0.40, 0.90, 0.85, 0.30)

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
	var gap := 6.0
	var glyph_width := 28.0
	var glyph_height := 54.0
	var total_width: float = float(glyph_count) * glyph_width + float(maxi(glyph_count - 1, 0)) * gap
	var scale_factor: float = minf(1.0, minf(size.x / maxf(total_width, 1.0), size.y / glyph_height))
	var width := glyph_width * scale_factor
	var height := glyph_height * scale_factor
	var spacing := gap * scale_factor
	var x: float = (size.x - (float(glyph_count) * width + float(maxi(glyph_count - 1, 0)) * spacing)) * 0.5
	var y: float = (size.y - height) * 0.5
	var cell_width := float(DIGIT_ATLAS.get_width()) / 10.0

	for character in value:
		if character == ".":
			draw_circle(Vector2(x + width * 0.5, y + height - 4.0 * scale_factor), 3.0 * scale_factor, MAIN_COLOR)
			x += width * 0.48 + spacing
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
