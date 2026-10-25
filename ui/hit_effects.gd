extends Node2D

## C-style hit burst: two short sweeping arcs, a compact flash and a few shards.
## All bursts share this node; expired bursts stop processing and drawing.
const COLORS := {
	"Perfect": Color("#FFD447"),
	"Great": Color("#4CA3FF"),
	"Good": Color("#55D66B")
}
const LIFETIME := 0.40
const MAX_BURSTS := 32
const ARC_STEPS := 14

var bursts: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 20
	set_process(not bursts.is_empty())

func emit_hit(center: Vector2, judgment: String, lane_width: float, upper: bool = false) -> void:
	if not COLORS.has(judgment) or lane_width <= 0.0:
		return
	if bursts.size() >= MAX_BURSTS:
		bursts.pop_front()
	bursts.append({
		"center": center, "color": COLORS[judgment], "age": 0.0,
		"scale": lane_width / 120.0, "upper": upper
	})
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	for index in range(bursts.size() - 1, -1, -1):
		bursts[index]["age"] = float(bursts[index]["age"]) + delta
		if float(bursts[index]["age"]) >= LIFETIME:
			bursts.remove_at(index)
	queue_redraw()
	if bursts.is_empty():
		set_process(false)

func _draw() -> void:
	for burst in bursts:
		_draw_burst(burst)

func _draw_burst(burst: Dictionary) -> void:
	var progress: float = clampf(float(burst["age"]) / LIFETIME, 0.0, 1.0)
	var expansion: float = 1.0 - pow(1.0 - progress, 3.0)
	var fade: float = pow(1.0 - progress, 1.7)
	var tint: Color = burst["color"]
	var factor: float = float(burst["scale"])
	var center: Vector2 = burst["center"]
	# Mirror upper hits so both play areas receive the same visual feedback.
	draw_set_transform(center, PI if bool(burst["upper"]) else 0.0, Vector2.ONE * factor)
	var radius: float = lerpf(15.0, 46.0, expansion)
	for side in range(2):
		var start: float = -2.95 + float(side) * PI + progress * 0.38
		_draw_arc_strip(radius, start, 1.15, 4.2 * (1.0 - progress * 0.7), tint, minf(fade * 1.35, 1.0))
		_draw_arc_strip(radius - 5.5, start + 0.12, 0.78, 1.65, tint, minf(fade * 0.62, 1.0))
	# Short-lived center flash and horizontal impact line.
	var flash: float = pow(maxf(1.0 - progress / 0.48, 0.0), 2.0)
	if flash > 0.0:
		draw_circle(Vector2.ZERO, 8.5 * flash + 2.0, Color(tint, flash * 0.28))
		draw_line(Vector2(-42, 0), Vector2(42, 0), Color(tint, minf(flash * 1.2, 1.0)), 2.2, true)
		var cross := PackedVector2Array([
			Vector2(-12, 0), Vector2(-2, -2), Vector2(0, -11), Vector2(2, -2),
			Vector2(12, 0), Vector2(2, 2), Vector2(0, 11), Vector2(-2, 2)
		])
		draw_colored_polygon(cross, Color(tint.lightened(0.62), minf(flash * 1.15, 1.0)))
	# A pair of small tapered shards; no large bloom or screen-wide particles.
	for side in range(2):
		var direction := Vector2.from_angle(-0.72 + float(side) * PI)
		var point: Vector2 = direction * lerpf(13.0, 49.0, expansion)
		var normal := direction.orthogonal()
		var shard := PackedVector2Array([
			point + direction * 5.5, point + normal * 2.1,
			point - direction * 4.0, point - normal * 1.5
		])
		draw_colored_polygon(shard, Color(tint, minf(fade * 1.25, 1.0)))
		var speck: Vector2 = direction.rotated(0.7) * lerpf(18.0, 37.0, expansion)
		draw_circle(speck, 1.35, Color(tint, minf(fade * 0.9, 1.0)))
	draw_set_transform(Vector2.ZERO)

func _draw_arc_strip(radius: float, start: float, sweep: float, width: float, tint: Color, alpha: float) -> void:
	var outline := PackedVector2Array()
	for index in range(ARC_STEPS + 1):
		var t: float = float(index) / float(ARC_STEPS)
		var thickness: float = width * sin(t * PI)
		outline.append(Vector2.from_angle(start + t * sweep) * (radius + thickness))
	for index in range(ARC_STEPS, -1, -1):
		var t: float = float(index) / float(ARC_STEPS)
		outline.append(Vector2.from_angle(start + t * sweep) * radius)
	draw_colored_polygon(outline, Color(tint, alpha))
