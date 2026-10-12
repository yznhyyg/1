extends ColorRect

const SWITCH_UP_TEXTURE: Texture2D = preload("res://assets/notes/switch_up.png")
const SWITCH_DOWN_TEXTURE: Texture2D = preload("res://assets/notes/switch_down.png")

var lane: int = 0
var hit_time: float = 0.0
var music_player: AudioStreamPlayer
var approach_time: float = 2.0
var spawn_y: float = 0.0
var target_y: float = 0.0
var boundary_y: float = 1280.0
var lane_start_x: float = 120.0
var lane_width: float = 120.0
var move_up := false
var switch_direction := "up"
var arrow_sprite: Sprite2D

func setup(new_lane: int, new_hit_time: float, new_music_player: AudioStreamPlayer, new_approach_time: float, new_spawn_y: float, new_target_y: float, new_boundary_y: float, new_lane_start_x: float, new_lane_width: float, new_move_up: bool) -> void:
	lane = new_lane
	hit_time = new_hit_time
	music_player = new_music_player
	approach_time = maxf(new_approach_time, 0.001)
	spawn_y = new_spawn_y
	target_y = new_target_y
	boundary_y = new_boundary_y
	lane_start_x = new_lane_start_x
	lane_width = new_lane_width
	move_up = new_move_up
	# 和普通音符一样，让 100 像素宽的箭头位于当前轨道正中央。
	position.x = lane_start_x + (lane % 4) * lane_width + (lane_width - size.x) / 2.0
	position.y = spawn_y
	color = Color.TRANSPARENT
	for child in get_children():
		child.hide()
	arrow_sprite = Sprite2D.new()
	arrow_sprite.texture = SWITCH_DOWN_TEXTURE if move_up else SWITCH_UP_TEXTURE
	arrow_sprite.position = size * 0.5
	arrow_sprite.scale = Vector2(size.x / arrow_sprite.texture.get_width(), size.y / arrow_sprite.texture.get_height())
	add_child(arrow_sprite)

func _process(_delta: float) -> void:
	if music_player == null:
		return
	var current_time := music_player.get_playback_position()
	var progress := 1.0 - (hit_time - current_time) / approach_time
	progress = maxf(progress, 0.0)
	position.y = lerp(spawn_y, target_y, progress)
	if move_up:
		if position.y + size.y < 0.0:
			queue_free()
	else:
		if position.y > boundary_y:
			queue_free()
