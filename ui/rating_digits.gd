extends Label

## Dynamic angular numerals for rating values.
## The label text remains available to tests and accessibility, while the
## visible glyphs are drawn from the same seven-segment geometry for every digit.

const DIGIT_SEGMENTS := {
	"0": [0, 1, 2, 3, 4, 5],
	"1": [1, 2],
	"2": [0, 1, 6, 4, 3],
	"3": [0, 1, 2, 3, 6],
	"4": [5, 6, 1, 2],
	"5": [0, 5, 6, 2, 3],
	"6": [0, 5, 6, 4, 2, 3],
	"7": [0, 1, 2],
	"8": [0, 1, 2, 3, 4, 5, 6],
	"9": [0, 1, 2, 3, 5, 6]
}

const MAIN_COLOR := Color("#FF75BC")
const EDGE_COLOR := Color("#66E7DA")

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
	var glyph_count := value.length()
	var gap := 7.0
	var glyph_width := 29.0
	var total_width := glyph_count * glyph_width + max(glyph_count - 1, 0) * gap
	var scale_factor := minf(1.0, minf(size.x / maxf(total_width, 1.0), size.y / 58.0))
	var width := glyph_width * scale_factor
	var height := 54.0 * scale_factor
	var spacing := gap * scale_factor
	var x := (size.x - (glyph_count * width + max(glyph_count - 1, 0) * spacing)) * 0.5
	var y := (size.y - height) * 0.5

	for character in value:
		if character == ".":
			draw_circle(Vector2(x + width * 0.5, y + height - 4.0 * scale_factor), 3.2 * scale_factor, MAIN_COLOR)
			x += width * 0.48 + spacing
			continue
		if DIGIT_SEGMENTS.has(character):
			_draw_digit(Vector2(x, y), width, height, scale_factor, DIGIT_SEGMENTS[character])
		x += width + spacing

func _draw_digit(origin: Vector2, width: float, height: float, scale_factor: float, segments: Array) -> void:
	var thickness := 7.0 * scale_factor
	var cut := 4.0 * scale_factor
	var horizontal_length := width - thickness
	var vertical_length := height * 0.5 - thickness * 0.5
	var positions := [
		Vector2(origin.x + thickness * 0.5, origin.y),
		Vector2(origin.x + width - thickness, origin.y + thickness * 0.5),
		Vector2(origin.x + width - thickness, origin.y + height * 0.5),
		Vector2(origin.x + thickness * 0.5, origin.y + height - thickness),
		Vector2(origin.x, origin.y + height * 0.5),
		Vector2(origin.x, origin.y + thickness * 0.5),
		Vector2(origin.x + thickness * 0.5, origin.y + height * 0.5 - thickness * 0.5)
	]
	for segment in segments:
		var points := _segment_points(int(segment), positions[int(segment)], horizontal_length, vertical_length, thickness, cut)
		var shadow := PackedVector2Array(points)
		for index in shadow.size():
			shadow[index] += Vector2(2.0 * scale_factor, 2.0 * scale_factor)
		draw_colored_polygon(shadow, Color(0.40, 0.90, 0.85, 0.30))
		draw_colored_polygon(PackedVector2Array(points), MAIN_COLOR)

func _segment_points(segment: int, position: Vector2, horizontal_length: float, vertical_length: float, thickness: float, cut: float) -> PackedVector2Array:
	if segment == 0 or segment == 3 or segment == 6:
		return PackedVector2Array([
			position + Vector2(cut, 0),
			position + Vector2(horizontal_length - cut, 0),
			position + Vector2(horizontal_length, thickness * 0.5),
			position + Vector2(horizontal_length - cut, thickness),
			position + Vector2(cut, thickness),
			position + Vector2(0, thickness * 0.5)
		])
	return PackedVector2Array([
		position + Vector2(thickness * 0.5, 0),
		position + Vector2(thickness, cut),
		position + Vector2(thickness, vertical_length - cut),
		position + Vector2(thickness * 0.5, vertical_length),
		position + Vector2(0, vertical_length - cut),
		position + Vector2(0, cut)
	])
