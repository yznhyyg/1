extends Node2D


# 预加载音符场景。
# 你的当前文件名如果确实是 note.tscn.tscn，
# 这里就必须写成这个完整路径。
const NOTE_SCENE = preload("res://note.tscn")
const ARROW_SCRIPT = preload("res://arrow_note.gd")
const COUNT_IN_CLICK: AudioStream = preload("res://assets/audio/count_in_click.wav")


# 谱面文件路径。以后新增歌曲时，只需复制 JSON 并修改这个路径。
@export_file("*.json") var chart_path: String = "res://songs/song_436/chart.json"

# 音符移动速度，单位为像素/秒。
# 可以在 Godot 检查器中修改；后续设置界面也可以修改这个变量。
@export_range(0.1, 12.0, 0.1) var note_speed: float = 1.0
const BASE_NOTE_SPEED := 70.0

# 当前歌曲文件夹。文件夹内可放 song.json、chart.json、music.ogg、artwork.png。
@export_dir var song_folder: String = "res://songs/song_436"

# 曲绘亮度：0 为全黑，1 为原图亮度。
@export_range(0.0, 1.0, 0.05) var artwork_brightness: float = 0.65
var chart_offset: float = 0.0

const LANE_COUNT := 8
var bottom_judge_line_y := 620.0
var top_judge_line_y := 92.0
var top_spawn_y := 300.0
var bottom_spawn_y := 0.0
var top_track_top := 0.0
var top_track_bottom := 530.0
var bottom_track_top := 750.0
var bottom_track_bottom := 1280.0
var lane_start_x := 120.0
var lane_width := 120.0


# 记录已经生成到谱面中的第几个音符。
var next_note_index: int = 0


# 保存已经生成的音符。
# 以后做判定、Miss 和清理时会用到。
var active_notes: Array[Node] = []
var active_arrows: Array[Node] = []
var arrow_template: ColorRect

const PERFECT_WINDOW := 0.080
const GREAT_WINDOW := 0.140
const GOOD_WINDOW := 0.180

var combo := 0
var combo_label: Label
var score_label: Label
var score: float = 0.0
var total_keys: int = 0
var points_per_key: float = 0.0
var perfect_count := 0
var great_count := 0
var good_count := 0
var miss_count := 0
var max_combo := 0
var result_sent := false
var pause_menu: Panel

# 当前可击打区域：0 表示下方 1~4，4 表示上方 5~8。
# 游戏开始时默认只能击打下方区域。
var active_lane_offset: int = 0
var supertime_active := false
var lane_offset_before_supertime: int = 0

# 记录 F/G/H/J 按下时实际对应的轨道。
# 这样长按过程中切换区域，松键仍会释放按下时的那条长音。
var pressed_lane_targets: Array[int] = [-1, -1, -1, -1]

var upper_lane_nodes: Array[ColorRect] = []
var lower_lane_nodes: Array[ColorRect] = []
var upper_track_skin: TextureRect
var lower_track_skin: TextureRect
const INACTIVE_AREA_FACTOR := 0.42



var chart: Array[Dictionary] = []
var supertime_ranges: Array[Dictionary] = []

# 歌曲开始前的反应等待和预备拍。
const COUNT_IN_REACTION_TIME := 1.0
var count_in_bpm := 0.0
var count_in_beats := 0
var count_in_active := false
var count_in_waiting := false
var count_in_elapsed := 0.0
var count_in_next_beat := 0
var count_in_interval := 0.5
var count_in_player: AudioStreamPlayer
var count_in_label: Label


func _ready() -> void:
	# 让根节点在暂停时继续接收 Esc，以便用同一个按键恢复游戏。
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 根节点需要处理暂停输入，但实际游戏内容必须跟随暂停状态。
	$PlayField.process_mode = Node.PROCESS_MODE_PAUSABLE
	$MusicPlayer.process_mode = Node.PROCESS_MODE_PAUSABLE
	if get_tree().has_meta("selected_song_folder"):
		song_folder = str(get_tree().get_meta("selected_song_folder"))
	if get_tree().has_meta("game_settings"):
		var settings: Dictionary = get_tree().get_meta("game_settings")
		note_speed = float(settings.get("note_speed", note_speed))
		artwork_brightness = float(settings.get("artwork_brightness", artwork_brightness))
		chart_offset = float(settings.get("chart_offset", chart_offset))
	_read_layout_from_scene()
	_cache_lane_nodes()
	_update_lane_visuals()
	arrow_template = get_node_or_null("PlayField/Arrow") as ColorRect
	_load_song_package()
	# 为了安全起见，按照目标时间从小到大排序。
	chart.sort_custom(_sort_notes_by_time)
	_validate_chart_side_conflicts()
	# 箭头提示符只负责提示切换方向，不参与分数计算。
	# 普通音符和长按音符各算一个可计分按键。
	total_keys = _count_scoring_notes()
	points_per_key = 1000000.0 / max(total_keys, 1)

	$UI.layer = 10
	combo_label = Label.new()
	combo_label.position = Vector2(210, 350)
	combo_label.custom_minimum_size = Vector2(300, 60)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.add_theme_font_size_override("font_size", 34)
	combo_label.modulate = Color("#C2185B")
	$UI.add_child(combo_label)
	_update_combo_label()
	score_label = Label.new()
	score_label.position = Vector2(470, 24)
	score_label.custom_minimum_size = Vector2(220, 45)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_font_size_override("font_size", 28)
	$UI.add_child(score_label)
	_update_score_label()
	_create_pause_menu()
	_create_count_in_ui()
	_start_song_or_count_in()


func _create_count_in_ui() -> void:
	count_in_player = AudioStreamPlayer.new()
	count_in_player.stream = COUNT_IN_CLICK
	$PlayField.add_child(count_in_player)
	count_in_label = Label.new()
	count_in_label.position = Vector2(210, 570)
	count_in_label.size = Vector2(300, 90)
	count_in_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_in_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_in_label.add_theme_font_size_override("font_size", 52)
	count_in_label.add_theme_color_override("font_color", Color("#7DEBFF"))
	count_in_label.visible = false
	$UI.add_child(count_in_label)


func _start_song_or_count_in() -> void:
	$MusicPlayer.stop()
	# 所有歌曲统一先留出 1 秒反应时间，再决定是否播放预备拍。
	# 这样没有 count_in 配置的歌曲也不会一进入场景就立即播放。
	if count_in_bpm > 0.0 and count_in_beats > 0:
		count_in_interval = 60.0 / count_in_bpm
	count_in_elapsed = 0.0
	count_in_next_beat = 0
	count_in_active = true
	count_in_waiting = true
	count_in_label.visible = true
	count_in_label.text = "准备"


func _play_count_in_beat() -> void:
	if count_in_next_beat >= count_in_beats:
		return
	count_in_player.play()
	count_in_label.text = str(count_in_next_beat + 1)
	count_in_next_beat += 1


func _update_count_in(delta: float) -> void:
	count_in_elapsed += delta
	# 预备拍前的固定反应时间：期间不播放点击音，也不推进谱面时间。
	if count_in_waiting:
		if count_in_elapsed < COUNT_IN_REACTION_TIME:
			return
		count_in_waiting = false
		count_in_elapsed = 0.0
		# 没有预备拍配置时，1 秒等待结束后直接开始正式音乐。
		if count_in_bpm <= 0.0 or count_in_beats <= 0:
			count_in_active = false
			count_in_label.visible = false
			$MusicPlayer.play()
			return
		# 有预备拍配置时，等待结束的瞬间播放第一下启动拍。
		_play_count_in_beat()
		return

	while count_in_next_beat < count_in_beats and count_in_elapsed >= count_in_next_beat * count_in_interval:
		_play_count_in_beat()
	# 最后一拍也占满一个完整拍长，然后音乐才从第 0 秒开始。
	if count_in_elapsed >= count_in_beats * count_in_interval:
		count_in_active = false
		count_in_label.visible = false
		$MusicPlayer.play()


func _create_pause_menu() -> void:
	# 暂停菜单放在高层 UI，并设置为始终处理输入，暂停树后仍可点击。
	pause_menu = Panel.new()
	pause_menu.position = Vector2(160, 430)
	pause_menu.size = Vector2(400, 380)
	pause_menu.visible = false
	pause_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	$UI.add_child(pause_menu)

	var title := Label.new()
	title.text = "游戏暂停"
	title.position = Vector2(0, 35)
	title.size = Vector2(400, 45)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	pause_menu.add_child(title)

	var continue_button := Button.new()
	continue_button.text = "继续游戏"
	continue_button.position = Vector2(80, 110)
	continue_button.size = Vector2(240, 55)
	continue_button.pressed.connect(_resume_game)
	pause_menu.add_child(continue_button)

	var restart_button := Button.new()
	restart_button.text = "重新开始"
	restart_button.position = Vector2(80, 180)
	restart_button.size = Vector2(240, 55)
	restart_button.pressed.connect(_restart_game)
	pause_menu.add_child(restart_button)

	var exit_button := Button.new()
	exit_button.text = "退出到主界面"
	exit_button.position = Vector2(80, 250)
	exit_button.size = Vector2(240, 55)
	exit_button.pressed.connect(_exit_to_menu)
	pause_menu.add_child(exit_button)

	var pause_button := Button.new()
	pause_button.text = "暂停"
	pause_button.position = Vector2(30, 25)
	pause_button.size = Vector2(110, 45)
	pause_button.pressed.connect(_pause_game)
	pause_button.process_mode = Node.PROCESS_MODE_ALWAYS
	$UI.add_child(pause_button)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			_resume_game()
		else:
			_pause_game()
		return
	if event.is_echo():
		return
	if get_tree().paused:
		return
	if count_in_active:
		return

	# 空格在下方/上方模式之间切换。
	# 切换区域不会释放正在按住的长条；只有实体按键松开时才会结束长按。
	if event is InputEventKey and event.pressed:
		# Supertime 期间上下两侧都开放，不需要切换方向；保留当前亮区用于关闭后恢复。
		if (event.keycode == KEY_SPACE or event.physical_keycode == KEY_SPACE) and supertime_active:
			return
		if event.keycode == KEY_SPACE or event.physical_keycode == KEY_SPACE:
			if active_lane_offset == 0:
				_try_judge_switch_arrow("up")
				active_lane_offset = 4
			else:
				_try_judge_switch_arrow("down")
				active_lane_offset = 0
			_update_lane_visuals()
			return

	# F/G/H/J 只判定当前激活的上下区域。
	for lane in range(4):
		var action := "lane_%d" % (lane + 1)
		if event.is_action_pressed(action):
			if supertime_active:
				# Supertime 上下两侧同时开放；正常谱面不会在同一时刻放置同键上下双音符。
				pressed_lane_targets[lane] = lane
				_try_judge_lane(lane)
				_try_judge_lane(lane + 4)
			else:
				var target_lane := lane + active_lane_offset
				pressed_lane_targets[lane] = target_lane
				_try_judge_lane(target_lane)
			return
		if event.is_action_released(action):
			if supertime_active:
				_release_hold(lane)
				_release_hold(lane + 4)
			else:
				var target_lane := pressed_lane_targets[lane]
				if target_lane < 0:
					target_lane = lane + active_lane_offset
				_release_hold(target_lane)
			pressed_lane_targets[lane] = -1
			return


func _pause_game() -> void:
	if result_sent:
		return
	pause_menu.visible = true
	$MusicPlayer.stream_paused = true
	if count_in_player != null:
		count_in_player.stream_paused = true
	get_tree().paused = true


func _resume_game() -> void:
	pause_menu.visible = false
	get_tree().paused = false
	$MusicPlayer.stream_paused = false
	if count_in_player != null:
		count_in_player.stream_paused = false


func _restart_game() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main.tscn")


func _exit_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _load_chart() -> void:
	var file := FileAccess.open(chart_path, FileAccess.READ)
	if file == null:
		push_error("无法读取谱面文件：" + chart_path)
		return
	var data = JSON.parse_string(file.get_as_text())
	_assign_chart_data(data)


func _load_song_package() -> void:
	var song_config_path := song_folder + "/song.json"
	if not FileAccess.file_exists(song_config_path):
		# 兼容旧项目：找不到歌曲包时继续使用原来的 chart_path 和 MusicPlayer。
		_load_chart()
		return
	var file := FileAccess.open(song_config_path, FileAccess.READ)
	var config = JSON.parse_string(file.get_as_text())
	if not config is Dictionary:
		push_error("song.json 必须是 JSON 对象")
		return
	var chart_file: String = song_folder + "/" + str(config.get("chart", "chart.json"))
	var music_file: String = song_folder + "/" + str(config.get("music", "music.ogg"))
	var artwork_file: String = song_folder + "/" + str(config.get("artwork", "artwork.png"))
	# 预备拍属于每首歌曲自己的配置。4/4 拍通常填写 beats: 4。
	var count_in = config.get("count_in", {})
	if count_in is Dictionary:
		count_in_bpm = maxf(float(count_in.get("bpm", 0.0)), 0.0)
		count_in_beats = maxi(int(count_in.get("beats", 0)), 0)
	_load_chart_from_path(chart_file)
	if ResourceLoader.exists(music_file):
		$MusicPlayer.stream = load(music_file)
	_load_artwork(artwork_file)


func _load_chart_from_path(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("无法读取谱面文件：" + path)
		return
	var data = JSON.parse_string(file.get_as_text())
	_assign_chart_data(data)


func _assign_chart_data(data) -> void:
	chart.clear()
	supertime_ranges.clear()
	if data is Array:
		# 数组谱面可在任意位置插入 {"type":"supertime", "start":..., "end":...}。
		for item in data:
			if item is Dictionary and str(item.get("type", "")) == "supertime":
				_add_supertime_range(item)
			elif item is Dictionary:
				chart.append(item)
	elif data is Dictionary:
		# 也支持对象格式：{"notes": [...], "supertime": [{"start":..., "end":...}]}。
		var notes = data.get("notes", [])
		if notes is Array:
			for item in notes:
				if item is Dictionary:
					chart.append(item)
		var ranges = data.get("supertime", [])
		if ranges is Dictionary:
			ranges = [ranges]
		if ranges is Array:
			for item in ranges:
				if item is Dictionary:
					_add_supertime_range(item)
	else:
		push_error("谱面必须是数组，或包含 notes/supertime 的 JSON 对象")
	supertime_ranges.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["start"]) < float(b["start"])
	)


func _add_supertime_range(data: Dictionary) -> void:
	var start := float(data.get("start", data.get("from", 0.0)))
	var end := float(data.get("end", data.get("to", start)))
	if end > start:
		supertime_ranges.append({"start": start, "end": end})


func _load_artwork(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var texture = load(path)
	$Artwork.texture = texture
	$Artwork.modulate = Color.WHITE
	$ArtworkShade.color = Color(0, 0, 0, 1.0 - artwork_brightness)


func _sort_notes_by_time(a: Dictionary, b: Dictionary) -> bool:
	# 如果 a 的时间更早，就让 a 排在前面。
	return float(a["time"]) < float(b["time"])


func _count_scoring_notes() -> int:
	var count := 0
	for note_data in chart:
		if not (note_data is Dictionary):
			continue
		var note_type := str(note_data.get("type", "normal"))
		if note_type == "switch_up" or note_type == "switch_down":
			continue
		count += 1
	return count


func _validate_chart_side_conflicts() -> void:
	# 同一实体键的上下轨道不能在同一判定窗口同时出现。
	# 这里不擅自改写玩家谱面，只报告具体冲突，方便制谱时修正时间。
	for i in range(chart.size()):
		var first: Dictionary = chart[i]
		var first_lane := _normalize_lane(int(first.get("lane", 1)))
		var first_column := first_lane % 4
		var first_side := first_lane >= 4
		var first_time := float(first.get("time", 0.0))
		for j in range(i + 1, chart.size()):
			var second: Dictionary = chart[j]
			var second_lane := _normalize_lane(int(second.get("lane", 1)))
			if second_lane % 4 != first_column or (second_lane >= 4) == first_side:
				continue
			if absf(float(second.get("time", 0.0)) - first_time) <= GOOD_WINDOW:
				push_warning("谱面存在上下同键冲突：lane %d 与 lane %d 的时间过近（%.3f / %.3f）。" % [
					first_lane + 1,
					second_lane + 1,
					first_time,
					float(second.get("time", 0.0))
				])


func _process(delta: float) -> void:
	# 根节点始终处理只是为了暂停菜单；暂停时不运行游戏逻辑。
	if get_tree().paused:
		return
	# 预备拍结束前音乐保持停止，因此不会生成音符、触发 Miss 或接受谱面判定。
	if count_in_active:
		_update_count_in(delta)
		return
	# 移除已经 queue_free 的音符，避免谱面越长每帧检查的对象越来越多。
	active_notes = active_notes.filter(func(note): return is_instance_valid(note))
	active_arrows = active_arrows.filter(func(arrow): return is_instance_valid(arrow))
	_update_lane_visuals()
	# 获取场景中的音乐播放器。
	var music_player := $MusicPlayer as AudioStreamPlayer

	# 如果播放器不存在，停止执行。
	if music_player == null:
		return

	# 获取音乐当前播放时间。
	var current_time: float = music_player.get_playback_position()
	_update_supertime_by_time(current_time)

	# 检查是否应该生成下一个音符。
	while next_note_index < chart.size():
		var note_data: Dictionary = chart[next_note_index]

		var note_hit_time: float = float(note_data["time"]) + chart_offset

		# 两组轨道距离判定线不同，各自按对应路程提前生成。
		var lane_for_spawn := _normalize_lane(int(note_data.get("lane", 0)))
		if current_time < note_hit_time - _approach_time_for_lane(lane_for_spawn):
			break

		_spawn_note(note_data, music_player)

		# 继续处理下一个谱面音符。
		next_note_index += 1

	_check_misses(current_time)
	_update_holds(current_time)

	# 音乐结束并且所有音符已处理后，进入结算界面。
	if not result_sent and not music_player.playing and next_note_index >= chart.size():
		var has_active_note := false
		for note in active_notes:
			if is_instance_valid(note) and not bool(note.get("judged")):
				has_active_note = true
				break
		var has_active_arrow := false
		for arrow in active_arrows:
			if is_instance_valid(arrow):
				has_active_arrow = true
				break
		if not has_active_note and not has_active_arrow:
			_open_result()


func _try_judge_lane(lane: int) -> void:
	var current_time: float = $MusicPlayer.get_playback_position()
	var best_note: Node = null
	var best_error := GOOD_WINDOW + 1.0

	for note in active_notes:
		if not is_instance_valid(note) or bool(note.get("judged")) or int(note.get("lane")) != lane:
			continue
		# 实际判定依据是按键时刻与谱面目标时刻的差值；
		# note.gd 会在目标时刻把音符头部底边对齐到判定线顶边，但这里不做像素碰撞检测。
		var error: float = abs(current_time - float(note.get("hit_time")))
		if error < best_error:
			best_error = error
			best_note = note

	if best_note == null or best_error > GOOD_WINDOW:
		return

	var result := "Good"
	if best_error <= PERFECT_WINDOW:
		result = "Perfect"
	elif best_error <= GREAT_WINDOW:
		result = "Great"

	best_note.set("judged", true)
	combo += 1
	max_combo = max(max_combo, combo)
	_update_combo_label()
	if bool(best_note.get("is_hold")):
		best_note.set("holding", true)
		best_note.set("head_result", result)
		best_note.set("hold_start_time", current_time)
	else:
		best_note.queue_free()
		_add_score(result)
		_show_judgment(result, lane)


func _try_judge_switch_arrow(direction: String) -> void:
	var current_time: float = $MusicPlayer.get_playback_position()
	for arrow in active_arrows:
		if not is_instance_valid(arrow):
			continue
		if str(arrow.get("switch_direction")) != direction:
			continue
		if absf(current_time - float(arrow.get("hit_time"))) <= GOOD_WINDOW:
			# 提示符不计分、不连击、不显示判定文字，只直接消失。
			arrow.queue_free()
			return


func _release_hold(lane: int) -> void:
	for note in active_notes:
		if not is_instance_valid(note) or not bool(note.get("holding")):
			continue
		if int(note.get("lane")) == lane:
			_finish_hold(note, $MusicPlayer.get_playback_position())
			return


func _update_holds(current_time: float) -> void:
	for note in active_notes:
		if not is_instance_valid(note) or not bool(note.get("holding")):
			continue
		var end_time := float(note.get("hit_time")) + float(note.get("duration"))
		if current_time >= end_time:
			_finish_hold(note, end_time)


func _finish_hold(note: Node, release_time: float) -> void:
	if bool(note.get("hold_finished")):
		return
	note.set("hold_finished", true)
	note.set("holding", false)
	var duration: float = float(note.get("duration"))
	var held_time: float = max(0.0, release_time - float(note.get("hold_start_time")))
	var result: String = str(note.get("head_result"))
	# 未达到总时长的 3/4 时，Perfect 降为 Great，Great 降为 Good。
	if held_time < duration * 0.75:
		if result == "Perfect":
			result = "Great"
		elif result == "Great":
			result = "Good"
	_add_score(result)
	_show_judgment(result, int(note.get("lane")), duration)
	note.queue_free()


func _update_supertime_by_time(current_time: float) -> void:
	var should_be_active := false
	for time_range in supertime_ranges:
		if current_time >= float(time_range["start"]) and current_time < float(time_range["end"]):
			should_be_active = true
			break
	if should_be_active == supertime_active:
		return
	if should_be_active:
		lane_offset_before_supertime = active_lane_offset
		supertime_active = true
	else:
		supertime_active = false
		active_lane_offset = lane_offset_before_supertime
	_update_lane_visuals()


func _check_misses(current_time: float) -> void:
	for note in active_notes:
		if not is_instance_valid(note) or bool(note.get("judged")):
			continue
		if current_time - float(note.get("hit_time")) > GOOD_WINDOW:
			if bool(note.get("is_hold")) and bool(note.get("holding")):
				continue
			note.set("judged", true)
			note.queue_free()
			combo = 0
			miss_count += 1
			_update_combo_label()
			_show_judgment("Miss", int(note.get("lane")))

func _approach_time() -> float:
	# 音符从出生点到判定线的距离除以速度，就是提前出现的时间。
	return bottom_judge_line_y / max(note_speed * BASE_NOTE_SPEED, 1.0)


func _update_combo_label() -> void:
	if combo_label != null:
		combo_label.text = "COMBO\n%d" % combo


func _add_score(result: String) -> void:
	var multiplier := 0.0
	match result:
		"Perfect":
			multiplier = 1.0
		"Great":
			multiplier = 0.7
		"Good":
			multiplier = 0.4
		"Miss":
			multiplier = 0.0
	score += points_per_key * multiplier
	match result:
		"Perfect": perfect_count += 1
		"Great": great_count += 1
		"Good": good_count += 1
	_update_score_label()


func _open_result() -> void:
	result_sent = true
	get_tree().set_meta("result_data", {
		# 使用歌曲文件夹名作为云端成绩的稳定编号，例如 song_436。
		"song_id": song_folder.get_file(),
		"score": int(round(score)),
		"perfect": perfect_count,
		"great": great_count,
		"good": good_count,
		"miss": miss_count,
		"max_combo": max_combo
	})
	get_tree().change_scene_to_file("res://result.tscn")


func _update_score_label() -> void:
	if score_label != null:
		score_label.text = "SCORE  %07d" % int(round(score))


func _show_judgment(text: String, lane: int, display_time: float = 0.35) -> void:
	# 每次判定都创建独立文字，避免连续判定互相覆盖。
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.custom_minimum_size = Vector2(120, 40)

	# 四条轨道中心分别是 460、580、700、820。
	# 判定线顶部约为 620，文字放在判定线上方 55 像素。
	var visual_lane := lane % 4
	var lane_center_x := lane_start_x + lane_width * 0.5 + visual_lane * lane_width
	# 上方判定文字放到判定线下方，下方判定文字仍放到判定线上方。
	var judgment_y := top_judge_line_y + 15.0 if lane >= 4 else bottom_judge_line_y - 65.0
	label.position = Vector2(lane_center_x - 60.0, judgment_y)

	match text:
		"Perfect":
			label.modulate = Color("#FFD447")
		"Great":
			label.modulate = Color("#4CA3FF")
		"Good":
			label.modulate = Color("#55D66B")
		"Miss":
			label.modulate = Color("#808080")

	$UI.add_child(label)
	label.z_index = 100

	var tween := create_tween()
	tween.tween_interval(max(display_time, 0.35))
	tween.tween_property(label, "modulate", Color(label.modulate, 0.0), 0.25)
	tween.tween_callback(label.queue_free)


func _spawn_note(
	note_data: Dictionary,
	music_player: AudioStreamPlayer
) -> void:
	var note_type := str(note_data.get("type", "normal"))
	if note_type == "switch_up" or note_type == "switch_down":
		_spawn_switch_arrow(note_data, music_player, note_type == "switch_up")
		return

	# 从音符场景创建一个实例。
	var note = NOTE_SCENE.instantiate()
	var normalized_lane := _normalize_lane(int(note_data["lane"]))

	# 把谱面数据传给音符。
	# 先初始化，再加入场景树，避免长按音符用默认尺寸/位置渲染一帧而闪现。
	note.setup(
		normalized_lane,
		float(note_data["time"]) + chart_offset,
		music_player,
		_approach_time_for_lane(normalized_lane),
		float(note_data.get("duration", 0.0)),
		note_speed * BASE_NOTE_SPEED,
		top_judge_line_y if normalized_lane >= 4 else bottom_judge_line_y,
		top_spawn_y if normalized_lane >= 4 else bottom_spawn_y,
		lane_start_x,
		lane_width,
		top_track_top if normalized_lane >= 4 else bottom_track_top,
		top_track_bottom if normalized_lane >= 4 else bottom_track_bottom
	)

	# 把已经初始化好的音符添加到 PlayField 下。
	# 这样音符的位置会使用 PlayField 的局部坐标。
	$PlayField.add_child(note)

	# 保存这个音符，之后判定系统会使用。
	active_notes.append(note)


func _spawn_switch_arrow(note_data: Dictionary, music_player: AudioStreamPlayer, _is_switch_up: bool) -> void:
	if arrow_template == null:
		push_error("找不到 PlayField/Arrow 模板，无法生成切换提示符")
		return
	var arrow := arrow_template.duplicate() as ColorRect
	arrow.set_script(ARROW_SCRIPT)
	arrow.visible = true
	var normalized_lane := _normalize_lane(int(note_data.get("lane", 1)))
	var switch_direction := "down" if normalized_lane >= 4 else "up"
	arrow.set("switch_direction", switch_direction)
	var travel_up := normalized_lane >= 4
	arrow.setup(normalized_lane, float(note_data["time"]) + chart_offset, music_player, _approach_time_for_lane(normalized_lane), top_spawn_y if travel_up else bottom_spawn_y, top_judge_line_y if travel_up else bottom_judge_line_y, -20.0 if travel_up else bottom_track_bottom, lane_start_x, lane_width, travel_up)
	$PlayField.add_child(arrow)
	active_arrows.append(arrow)

func _approach_time_for_lane(lane: int) -> float:
	if lane >= 4:
		return (top_spawn_y - top_judge_line_y) / max(note_speed * BASE_NOTE_SPEED, 1.0)
	return (bottom_judge_line_y - bottom_spawn_y) / max(note_speed * BASE_NOTE_SPEED, 1.0)

func _read_layout_from_scene() -> void:
	# 判定线和轨道位置以场景为准，便于以后直接拖动节点调整布局。
	var bottom_line := get_node_or_null("PlayField/JudgeLine") as Control
	var top_line := get_node_or_null("PlayField/TopJudgeLine") as Control
	var top_lane := get_node_or_null("PlayField/Lane5") as Control
	if bottom_line != null:
		bottom_judge_line_y = bottom_line.position.y
	if top_line != null:
		top_judge_line_y = top_line.position.y
	if top_lane != null:
		lane_start_x = top_lane.global_position.x
		lane_width = top_lane.size.x
		top_track_top = top_lane.global_position.y
		top_track_bottom = top_lane.global_position.y + top_lane.size.y
		top_spawn_y = top_track_bottom
	var bottom_lane := get_node_or_null("PlayField/Lane5/Lane1") as Control
	if bottom_lane != null:
		bottom_track_top = bottom_lane.global_position.y
		bottom_track_bottom = bottom_lane.global_position.y + bottom_lane.size.y
		bottom_spawn_y = bottom_track_top


func _cache_lane_nodes() -> void:
	upper_lane_nodes.clear()
	lower_lane_nodes.clear()
	upper_track_skin = get_node_or_null("PlayField/UpperTrackSkin") as TextureRect
	lower_track_skin = get_node_or_null("PlayField/LowerTrackSkin") as TextureRect
	for index in range(4):
		var upper := get_node_or_null("PlayField/Lane%d" % (index + 5)) as ColorRect
		if upper != null:
			upper_lane_nodes.append(upper)
			var lower := upper.get_node_or_null("Lane%d" % (index + 1)) as ColorRect
			if lower != null:
				lower_lane_nodes.append(lower)


func _update_lane_visuals() -> void:
	# 四条轨道现在由一张整体贴图绘制；整体贴图负责外框和三条内部边界。
	# 这里同时调整整体贴图和旧的轨道节点，保证上下区域切换时一起变暗。
	var lower_active := active_lane_offset == 0
	if supertime_active:
		lower_active = true
	if is_instance_valid(lower_track_skin):
		lower_track_skin.self_modulate = Color.WHITE if lower_active else Color(INACTIVE_AREA_FACTOR, INACTIVE_AREA_FACTOR, INACTIVE_AREA_FACTOR, 1.0)
	if is_instance_valid(upper_track_skin):
		upper_track_skin.self_modulate = Color.WHITE if supertime_active or not lower_active else Color(INACTIVE_AREA_FACTOR, INACTIVE_AREA_FACTOR, INACTIVE_AREA_FACTOR, 1.0)
	for lane_node in lower_lane_nodes:
		if is_instance_valid(lane_node):
			lane_node.self_modulate = Color.WHITE if lower_active else Color(INACTIVE_AREA_FACTOR, INACTIVE_AREA_FACTOR, INACTIVE_AREA_FACTOR, 1.0)
	for lane_node in upper_lane_nodes:
		if is_instance_valid(lane_node):
			lane_node.self_modulate = Color.WHITE if supertime_active or not lower_active else Color(INACTIVE_AREA_FACTOR, INACTIVE_AREA_FACTOR, INACTIVE_AREA_FACTOR, 1.0)

	for note in active_notes:
		if not is_instance_valid(note):
			continue
		var note_lane := int(note.get("lane"))
		var note_active := supertime_active or (note_lane < 4 and lower_active) or (note_lane >= 4 and not lower_active)
		note.modulate = Color.WHITE if note_active else Color(INACTIVE_AREA_FACTOR, INACTIVE_AREA_FACTOR, INACTIVE_AREA_FACTOR, 1.0)

func _normalize_lane(raw_lane: int) -> int:
	# 谱面统一使用玩家看到的1~8编号：1~4下方，5~8上方。
	# 代码内部使用0~7，因此统一减1。
	return clampi(raw_lane - 1, 0, LANE_COUNT - 1)
