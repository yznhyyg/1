extends Node2D

const NOTE_TEXTURE: Texture2D = preload("res://assets/notes/note_normal.png")
const HOLD_HEAD_TEXTURE: Texture2D = preload("res://assets/notes/hold_head.png")
const HOLD_HEAD_NEW_TEXTURE: Texture2D = preload("res://assets/notes/hold_head_new.png")
const HOLD_BODY_TEXTURE: Texture2D = preload("res://assets/notes/hold_body_continuous.png")
const HOLD_OVERLAP := 2.0

var lane: int = 0
var hit_time: float = 0.0
var judged: bool = false
var duration: float = 0.0
var is_hold: bool = false
var holding: bool = false
var hold_finished: bool = false
var hold_start_time: float = 0.0
var head_result: String = "Good"
var music_player: AudioStreamPlayer
var approach_time: float = 2.0
var judge_line_y: float = 620.0
var spawn_y: float = 0.0
var lane_start_x: float = 120.0
var note_width: float = 100.0
var lane_width: float = 120.0
var head_height: float = 16.0
var body_height: float = 0.0
var move_speed: float = 300.0
var reverse_direction := false
var target_y := 620.0
var start_y := 0.0
var track_top := 0.0
var track_bottom := 720.0

func setup(new_lane: int, new_hit_time: float, new_music_player: AudioStreamPlayer, new_approach_time: float = 2.0, new_duration: float = 0.0, new_move_speed: float = 300.0, new_judge_y: float = 620.0, new_spawn_y: float = 0.0, new_lane_start_x: float = 120.0, new_lane_width: float = 120.0, new_track_top: float = 0.0, new_track_bottom: float = 720.0) -> void:
	lane = new_lane
	hit_time = new_hit_time
	music_player = new_music_player
	approach_time = max(new_approach_time, 0.001)
	duration = max(new_duration, 0.0)
	move_speed = new_move_speed
	reverse_direction = lane >= 4
	target_y = new_judge_y
	start_y = new_spawn_y
	lane_start_x = new_lane_start_x
	lane_width = new_lane_width
	track_top = new_track_top
	track_bottom = new_track_bottom
	is_hold = duration > 0.0
	body_height = duration * move_speed if is_hold else 0.0
	var head := get_node("Head") as TextureRect
	var body := get_node("Body") as TextureRect
	if is_hold:
		# 新的 Hold 头部沿用 Tap 的六边形轮廓，但亮度略低于普通 Tap。
		head.texture = HOLD_HEAD_NEW_TEXTURE
		head.modulate = Color.WHITE
		# 宽度保持 100，压低头部到 16 像素，视觉比例约为 6.25:1。
		head_height = 16.0
		# 主体是一张完整的连续长条，只按 Hold 的实际长度整体缩放，不进行平铺。
		body.texture = HOLD_BODY_TEXTURE
		body.stretch_mode = TextureRect.STRETCH_SCALE
	else:
		head.texture = NOTE_TEXTURE
		head.modulate = Color.WHITE
		# 普通音符宽 100、高 16，视觉上更扁、更接近音游常见比例。
		head_height = 16.0
	head.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	head.stretch_mode = TextureRect.STRETCH_SCALE
	body.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	head.size = Vector2(note_width, head_height)
	body.size = Vector2(note_width, body_height)
	# 主体向头部方向多压入 2 像素，避免头部与主体之间出现断缝。
	body.position = Vector2(0.0, head_height - HOLD_OVERLAP if reverse_direction else -body_height + HOLD_OVERLAP)
	body.visible = is_hold
	position.x = lane_start_x + (lane % 4) * lane_width + (lane_width - note_width) / 2.0

func _process(_delta: float) -> void:
	if music_player == null:
		return
	var current_time: float = music_player.get_playback_position()
	var progress: float = 1.0 - (hit_time - current_time) / approach_time
	# 只限制音符不能早于出生点；到达判定线后允许继续下落。
	# 主场景会在超过 Good 窗口后将它判为 Miss 并删除。
	progress = maxf(progress, 0.0)
	# target_y 是判定线顶部的 y 坐标。把音符头部矩形的底边放到 target_y，
	# 因此在 hit_time 对应的理想时刻，音符最下面的绘制边界正好贴住判定线最上边界。
	# 这里是按节点矩形尺寸定位，不是逐像素碰撞检测。
	var head_target_y: float = target_y - head_height
	if is_hold and holding:
		var held_time: float = clampf(current_time - hit_time, 0.0, duration)
		var remaining: float = 1.0 - held_time / max(duration, 0.001)
		var current_body_height: float = body_height * remaining
		var body := get_node("Body") as TextureRect
		body.size.y = current_body_height
		body.position.y = head_height - HOLD_OVERLAP if reverse_direction else -current_body_height + HOLD_OVERLAP
		position.y = head_target_y
	else:
		if is_hold:
			# 非持有阶段每帧恢复目标长度，再根据轨道边界裁剪。
			var body := get_node("Body") as TextureRect
			body.size.y = body_height
		position.y = lerp(start_y, head_target_y, progress)
	_update_body_clip()

func _update_body_clip() -> void:
	if not is_hold:
		return
	var body := get_node("Body") as TextureRect
	if reverse_direction:
		# 上方轨道的长条从头部向下，不能超过上方轨道底部。
		var available := track_bottom - (position.y + head_height)
		body.size.y = minf(body.size.y, maxf(available, 0.0))
		body.position.y = head_height - HOLD_OVERLAP
	else:
		# 下方轨道的长条从头部向上，不能越过下方轨道顶部。
		var available := position.y - track_top
		body.size.y = minf(body.size.y, maxf(available, 0.0))
		body.position.y = -body.size.y + HOLD_OVERLAP
