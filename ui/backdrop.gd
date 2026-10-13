extends Control

var minimal := false

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#090F1D"))
	if minimal:
		# Subtle light behind the partner, with no grid or rhythm bars on the home page.
		var factor := size / Vector2(720, 1280)
		for layer in range(32):
			draw_circle(Vector2(540, 620) * factor, (540.0 - layer * 12.0) * factor.x, Color(0.25, 0.33, 0.49, 0.012))
		return
	# A quiet perspective grid and rhythm bars, drawn at any viewport size.
	var scale_factor := size / Vector2(720, 1280)
	for index in range(12):
		var x := float(index) * 80.0 - 100.0
		draw_line(Vector2(360, 450) * scale_factor, Vector2(x, 1280) * scale_factor, Color(0.27, 0.36, 0.56, 0.10), 1.0)
	for y in range(740, 1280, 90):
		draw_line(Vector2(0, y) * scale_factor, Vector2(720, y) * scale_factor, Color(0.27, 0.36, 0.56, 0.10), 1.0)
	for index in range(16):
		var height := 35.0 + float((index * 37) % 100)
		var color := Color("#66E7DA") if index % 3 == 0 else Color("#9C87FF")
		color.a = 0.10
		draw_rect(Rect2(Vector2(42 + index * 42, 380 - height) * scale_factor, Vector2(18, height) * scale_factor), color)
	draw_line(Vector2(40, 18) * scale_factor, Vector2(90, 18) * scale_factor, Color("#66E7DA"), 3)
	draw_line(Vector2(630, 1240) * scale_factor, Vector2(680, 1240) * scale_factor, Color("#9C87FF"), 3)
