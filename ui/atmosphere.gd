extends Control

## Lightweight animated overlay for menu backgrounds.
## It draws a few fixed dust points and two occasional meteor streaks without
## creating particle nodes or touching the gameplay scene.

var elapsed := 0.0
const BASE_SIZE := Vector2(720.0, 1280.0)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	elapsed = fmod(elapsed + delta, 100000.0)
	queue_redraw()

func _draw() -> void:
	var scale := Vector2(size.x / BASE_SIZE.x, size.y / BASE_SIZE.y)
	var dust := Color(0.60, 0.78, 1.0, 0.16)
	var dust_soft := Color(0.40, 0.90, 0.88, 0.09)
	var points := [
		Vector2(92, 146), Vector2(178, 226), Vector2(286, 118), Vector2(410, 178),
		Vector2(548, 132), Vector2(635, 264), Vector2(74, 592), Vector2(650, 612),
		Vector2(118, 936), Vector2(296, 1010), Vector2(570, 902), Vector2(658, 1138)
	]
	for index in points.size():
		var pulse := 0.78 + sin(elapsed * 0.53 + float(index) * 1.8) * 0.12 + sin(elapsed * 0.91 + float(index)) * 0.06
		var point: Vector2 = points[index] * scale
		draw_circle(point, (1.4 + float(index % 2)) * scale.x, dust if index % 3 else dust_soft * pulse)

	_draw_meteor(Vector2(540, 190), 17.0, 0.0, scale)
	_draw_meteor(Vector2(160, 730), 23.0, 8.5, scale)

func _draw_meteor(origin: Vector2, cycle: float, phase_offset: float, scale: Vector2) -> void:
	var phase := fmod(elapsed + phase_offset, cycle)
	if phase > 1.45:
		return
	var progress := phase / 1.45
	var eased := progress * progress * (3.0 - 2.0 * progress)
	var position := origin + Vector2(-eased * 260.0, eased * 190.0)
	var alpha := sin(progress * PI) * 0.68
	var head := position * scale
	var tail := (position + Vector2(74.0, -54.0)) * scale
	draw_line(tail, head, Color(0.62, 0.88, 1.0, alpha * 0.24), 2.0 * scale.x)
	draw_line(head, head + Vector2(7.0, -5.0) * scale, Color(0.78, 1.0, 1.0, alpha), 1.6 * scale.x)
