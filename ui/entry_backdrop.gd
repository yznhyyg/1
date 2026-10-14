extends Control

## A quiet, animated backdrop for the entry/login screen.
## It is drawn procedurally so it stays sharp at every window size.

var elapsed := 0.0
var _base_size := Vector2(720.0, 1280.0)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	elapsed = fmod(elapsed + delta, TAU * 100.0)
	queue_redraw()

func _draw() -> void:
	var scale_factor := size / _base_size
	var pulse := (sin(elapsed * 0.55) + 1.0) * 0.5

	draw_rect(Rect2(Vector2.ZERO, size), Color("#070C19"))

	# Two broad pools of colour give the page depth without competing with the form.
	_draw_glow(Vector2(555.0, 265.0) * scale_factor, 430.0 * scale_factor.x, Color("#5C4AC8"), 0.15 + pulse * 0.025)
	_draw_glow(Vector2(125.0, 980.0) * scale_factor, 330.0 * scale_factor.x, Color("#167A87"), 0.10)

	# A thin perspective grid anchors the lower half of the screen.
	for index in range(11):
		var x := float(index) * 82.0 - 150.0
		draw_line(Vector2(360.0, 640.0) * scale_factor, Vector2(x, 1280.0) * scale_factor, Color(0.30, 0.42, 0.68, 0.075), 1.0)
	for y in range(710, 1280, 92):
		draw_line(Vector2(0.0, y) * scale_factor, Vector2(720.0, y) * scale_factor, Color(0.30, 0.42, 0.68, 0.06), 1.0)

	# Bars and arcs suggest a track preview behind the login card.
	var bars := [58.0, 96.0, 42.0, 132.0, 74.0, 116.0, 52.0, 88.0, 142.0]
	for index in range(bars.size()):
		var bar_height: float = bars[index]
		var x := 414.0 + float(index) * 30.0
		var y := 474.0 - bar_height
		var bar_color := Color("#66E7DA") if index % 3 == 0 else Color("#9C87FF")
		bar_color.a = 0.12
		draw_rect(Rect2(Vector2(x, y) * scale_factor, Vector2(14.0, bar_height) * scale_factor), bar_color)

	var ring_center := Vector2(548.0, 260.0) * scale_factor
	for index in range(3):
		var ring_color := Color("#9C87FF")
		ring_color.a = 0.16 - float(index) * 0.035
		draw_arc(ring_center, (104.0 + index * 28.0) * scale_factor.x, -2.55, 0.75, 42, ring_color, 2.0)
	draw_line(Vector2(440.0, 286.0) * scale_factor, Vector2(646.0, 286.0) * scale_factor, Color(0.40, 0.90, 0.85, 0.14), 1.0)

	# Small fixed particles keep the empty corners from feeling flat.
	var particles := [Vector2(78, 174), Vector2(196, 116), Vector2(626, 126), Vector2(664, 570), Vector2(48, 1060), Vector2(610, 1080), Vector2(324, 1118)]
	for index in range(particles.size()):
		var particle_color := Color("#66E7DA") if index % 2 == 0 else Color("#9C87FF")
		particle_color.a = 0.30
		draw_circle(particles[index] * scale_factor, (2.0 + (index % 2)) * scale_factor.x, particle_color)

	draw_line(Vector2(40.0, 28.0) * scale_factor, Vector2(110.0, 28.0) * scale_factor, Color("#66E7DA"), 3.0)
	draw_line(Vector2(610.0, 1238.0) * scale_factor, Vector2(680.0, 1238.0) * scale_factor, Color("#9C87FF"), 3.0)

func _draw_glow(center: Vector2, radius: float, color: Color, strength: float) -> void:
	for index in range(24):
		var layer := float(24 - index) / 24.0
		var glow := color
		glow.a = strength * layer * layer
		draw_circle(center, radius * layer, glow)
