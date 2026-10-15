extends Control

## Low-contrast decorative pattern for the Cyan Glass rating card.
## It stays behind the logo and score so it adds texture without reducing legibility.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var ink := Color(0.25, 0.72, 0.78, 0.075)
	var violet := Color(0.48, 0.40, 0.84, 0.055)
	for offset in range(-180, 420, 28):
		draw_line(Vector2(offset, 130), Vector2(offset + 150, 0), ink, 1.0)
	for x in range(18, 260, 42):
		for y in range(16, 130, 38):
			draw_circle(Vector2(x, y), 1.5, violet)
	for radius in [48.0, 82.0, 116.0]:
		draw_arc(Vector2(255, 132), radius, PI * 1.08, PI * 1.72, 24, ink, 1.0)
