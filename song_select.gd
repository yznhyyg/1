extends Control

const RatingSystem = preload("res://rating_system.gd")

const UI = preload("res://ui/rhythm_ui.gd")

var songs: Array[Dictionary] = []
var selected_index := 0
var level_label: Label
var title_label: Label
var artwork: TextureRect
var best_score_label: Label
var list_box: VBoxContainer
var song_buttons: Array[Button] = []
var difficulty_box: HBoxContainer
var selected_difficulty_key := "advanced"
var preview_player: AudioStreamPlayer
var best_scores: Dictionary = {}
var preview_end_time: float = 0.0
var preview_start_time: float = 30.0
var preview_duration: float = 15.0
var preview_fade_in: float = 1.0
var preview_fade_out: float = 1.0
var preview_is_fading: bool = false
var preview_tween: Tween

func _ready() -> void:
	preview_player = AudioStreamPlayer.new()
	preview_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(preview_player)
	preview_player.finished.connect(_on_preview_finished)

	# 整个页面只使用深色背景、白色文字和一种紫色强调色，保持简洁现代。
	UI.setup(self)

	var page_mark := Label.new()
	page_mark.text = "SELECT TRACK"
	page_mark.position = Vector2(32, 25)
	page_mark.size = Vector2(300, 30)
	page_mark.add_theme_color_override("font_color", Color("#8B93A7"))
	page_mark.add_theme_font_size_override("font_size", 15)
	add_child(page_mark)

	var back := Button.new()
	back.text = "←  返回"
	back.position = Vector2(32, 63)
	back.size = Vector2(122, 46)
	_style_secondary_button(back)
	back.pressed.connect(_back)
	add_child(back)
	var settings := Button.new()
	settings.text = "设置  ⚙"
	settings.position = Vector2(566, 63)
	settings.size = Vector2(122, 46)
	_style_secondary_button(settings)
	settings.pressed.connect(_open_settings)
	add_child(settings)

	# 曲绘、歌名和最好成绩属于同一张信息卡片。
	var hero_card := Panel.new()
	hero_card.position = Vector2(32, 130)
	hero_card.size = Vector2(656, 548)
	hero_card.add_theme_stylebox_override("panel", _make_panel_style(Color("#131C2E"), 18, Color("#303C57")))
	add_child(hero_card)

	title_label = Label.new()
	title_label.position = Vector2(56, 151)
	title_label.size = Vector2(430, 47)
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color("#F5F7FC"))
	title_label.add_theme_font_size_override("font_size", 30)
	add_child(title_label)

	level_label = UI.label(self, "LV —", Rect2(504, 151, 160, 47), 24, UI.CYAN)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var now_playing := Label.new()
	now_playing.text = "TRACK PREVIEW / 曲目试听"
	now_playing.position = Vector2(56, 190)
	now_playing.size = Vector2(250, 24)
	now_playing.add_theme_color_override("font_color", UI.ACCENT)
	now_playing.add_theme_font_size_override("font_size", 13)
	add_child(now_playing)

	artwork = TextureRect.new()
	artwork.position = Vector2(56, 225)
	artwork.size = Vector2(608, 342)
	artwork.clip_contents = true
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	artwork.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(artwork)

	# 一条轻量分隔线，避免成绩信息与曲绘黏在一起。
	var divider := ColorRect.new()
	divider.position = Vector2(56, 588)
	divider.size = Vector2(608, 1)
	divider.color = Color("#293044")
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(divider)

	best_score_label = Label.new()
	best_score_label.position = Vector2(56, 601)
	best_score_label.size = Vector2(608, 52)
	best_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	best_score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	best_score_label.add_theme_color_override("font_color", Color("#DCE1ED"))
	best_score_label.add_theme_font_size_override("font_size", 20)
	best_score_label.text = "正在读取最高成绩……"
	add_child(best_score_label)

	var list_title := Label.new()
	list_title.text = "曲库 / LIBRARY"
	list_title.position = Vector2(32, 708)
	list_title.size = Vector2(300, 36)
	list_title.add_theme_color_override("font_color", Color("#F5F7FC"))
	list_title.add_theme_font_size_override("font_size", 22)
	add_child(list_title)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(32, 755)
	scroll.size = Vector2(656, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	list_box = VBoxContainer.new()
	list_box.custom_minimum_size = Vector2(656, 0)
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation", 10)
	scroll.add_child(list_box)

	var difficulty_title := Label.new()
	difficulty_title.text = "选择难度 / DIFFICULTY"
	difficulty_title.position = Vector2(32, 1062)
	difficulty_title.size = Vector2(300, 24)
	difficulty_title.add_theme_color_override("font_color", Color("#9BA6BE"))
	difficulty_title.add_theme_font_size_override("font_size", 14)
	add_child(difficulty_title)
	difficulty_box = HBoxContainer.new()
	difficulty_box.position = Vector2(32, 1088)
	difficulty_box.size = Vector2(656, 58)
	difficulty_box.add_theme_constant_override("separation", 8)
	add_child(difficulty_box)

	var start := Button.new()
	start.text = "开始游戏     ENTER  →"
	start.position = Vector2(32, 1165)
	start.size = Vector2(656, 76)
	start.add_theme_font_size_override("font_size", 21)
	start.add_theme_color_override("font_color", Color.WHITE)
	start.add_theme_color_override("font_hover_color", Color.WHITE)
	start.add_theme_stylebox_override("normal", _make_button_style(Color("#6757E8"), Color("#6757E8"), 16))
	start.add_theme_stylebox_override("hover", _make_button_style(Color("#796AF2"), Color("#9186FF"), 16))
	start.add_theme_stylebox_override("pressed", _make_button_style(Color("#5547C8"), Color("#5547C8"), 16))
	start.pressed.connect(_start_game)
	add_child(start)

	UI.primary(start)
	UI.reveal(self)
	_load_songs()
	# 登录页已经预加载了全部成绩，这里只读取内存缓存。
	best_scores = get_tree().get_meta("song_scores", {})
	if not best_scores is Dictionary:
		best_scores = {}
	_update_best_score_display()


func _make_panel_style(color: Color, radius: int, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border_color
	return style


func _make_button_style(color: Color, border_color: Color, radius: int) -> StyleBoxFlat:
	var style := _make_panel_style(color, radius, border_color)
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	return style


func _style_secondary_button(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color("#DCE1ED"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _make_button_style(Color("#131C2E"), Color("#303C57"), 12))
	button.add_theme_stylebox_override("hover", _make_button_style(Color("#1C2231"), UI.ACCENT, 12))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color("#242A3D"), UI.ACCENT, 12))

func _process(_delta: float) -> void:
	if preview_player != null and preview_player.playing and not preview_is_fading:
		if preview_player.get_playback_position() >= preview_end_time - preview_fade_out:
			_loop_preview()

func _load_songs() -> void:
	# Read current constants so changing song.json takes effect without logging in again.
	songs = RatingSystem.load_catalog()
	get_tree().set_meta("song_catalog", songs)
	_create_song_buttons()

func _create_song_buttons() -> void:
	song_buttons.clear()
	for index in songs.size():
		var button := Button.new()
		button.text = "  %02d     %s     ·     %s" % [index + 1, str(songs[index].get("title", "未命名歌曲")), RatingSystem.level_text(songs[index])]
		button.custom_minimum_size = Vector2(656, 64)
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 19)
		button.add_theme_color_override("font_color", Color("#B8C0D2"))
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_stylebox_override("normal", _make_button_style(Color("#111621"), Color("#202738"), 12))
		button.add_theme_stylebox_override("hover", _make_button_style(Color("#191F2E"), Color("#4D5872"), 12))
		button.add_theme_stylebox_override("pressed", _make_button_style(Color("#20263A"), UI.ACCENT, 12))
		button.pressed.connect(_select_song.bind(index))
		list_box.add_child(button)
		song_buttons.append(button)
	if not songs.is_empty():
		_select_song(0)

func _build_difficulty_buttons(song: Dictionary) -> void:
	if difficulty_box == null:
		return
	for child in difficulty_box.get_children():
		child.queue_free()
	var difficulties = song.get("difficulties", {})
	if not difficulties is Dictionary:
		difficulties = {}
	var order := ["beginner", "normal", "advanced", "master"]
	var first_key := ""
	for key in order:
		if key == "master" and not bool(song.get("master_enabled", false)):
			continue
		var item = difficulties.get(key, {})
		if not item is Dictionary:
			continue
		var chart := str(item.get("chart", ""))
		if chart.is_empty():
			continue
		if first_key.is_empty():
			first_key = key
		var button := Button.new()
		button.set_meta("difficulty_key", str(key))
		button.text = "%s    %s" % [str(item.get("name", key)), RatingSystem.level_text_for_difficulty(song, str(key))]
		button.custom_minimum_size = Vector2(158, 52)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(_select_difficulty.bind(key))
		difficulty_box.add_child(button)
	selected_difficulty_key = first_key if not first_key.is_empty() else "advanced"
	_update_difficulty_button_styles()

func _select_difficulty(key: String) -> void:
	selected_difficulty_key = key
	if selected_index < songs.size():
		level_label.text = "%s · %s" % [RatingSystem.level_text_for_difficulty(songs[selected_index], selected_difficulty_key), _difficulty_name(selected_difficulty_key)]
	_update_difficulty_button_styles()
	_update_best_score_display()

func _update_difficulty_button_styles() -> void:
	if difficulty_box == null:
		return
	for child in difficulty_box.get_children():
		if not child is Button:
			continue
		var button := child as Button
		var active := str(button.get_meta("difficulty_key", "")) == selected_difficulty_key
		button.add_theme_color_override("font_color", Color.WHITE if active else Color("#B8C0D2"))
		button.add_theme_stylebox_override("normal", _make_button_style(Color("#211F3B") if active else Color("#111621"), UI.ACCENT if active else Color("#202738"), 6))
		button.add_theme_stylebox_override("hover", _make_button_style(Color("#29264A"), UI.ACCENT, 6))

func _difficulty_name(key: String) -> String:
	var song: Dictionary = songs[selected_index] if selected_index < songs.size() else {}
	var difficulties = song.get("difficulties", {})
	var item = difficulties.get(key, {}) if difficulties is Dictionary else {}
	return str(item.get("name", key)) if item is Dictionary else key

func _open_settings() -> void:
	if preview_player != null:
		preview_player.stop()
	get_tree().change_scene_to_file("res://settings.tscn")

func _select_song(index: int) -> void:
	selected_index = index
	_update_song_button_styles()
	var song: Dictionary = songs[index]
	_start_preview(song)
	title_label.text = str(song.get("title", "未命名歌曲"))
	_build_difficulty_buttons(song)
	level_label.text = "%s · %s" % [RatingSystem.level_text_for_difficulty(song, selected_difficulty_key), _difficulty_name(selected_difficulty_key)]
	_update_best_score_display()
	var artwork_path := str(song["folder"]) + "/" + str(song.get("artwork", "artwork.png"))
	if ResourceLoader.exists(artwork_path):
		artwork.texture = load(artwork_path)


func _update_song_button_styles() -> void:
	for index in song_buttons.size():
		var button := song_buttons[index]
		if index == selected_index:
			button.add_theme_color_override("font_color", Color.WHITE)
			button.add_theme_stylebox_override("normal", _make_button_style(Color("#211F3B"), UI.ACCENT, 12))
		else:
			button.add_theme_color_override("font_color", Color("#B8C0D2"))
			button.add_theme_stylebox_override("normal", _make_button_style(Color("#111621"), Color("#202738"), 12))

func _get_session() -> Dictionary:
	var session = get_tree().get_meta("supabase_session", {})
	return session if session is Dictionary else {}

func _update_best_score_display() -> void:
	if songs.is_empty() or best_score_label == null:
		return
	var song_folder := str(songs[selected_index].get("folder", ""))
	var song_id := song_folder.get_file()
	var key := RatingSystem.score_key(song_id, selected_difficulty_key)
	if not best_scores.has(key) and selected_difficulty_key == "advanced":
		key = song_id
	if not best_scores.has(key):
		best_score_label.text = "BEST   —          ·          最高分   0000000"
		return
	var record: Dictionary = best_scores[key]
	best_score_label.text = "BEST   %s          ·          最高分   %07d" % [
		str(record.get("grade", "-")),
		int(record.get("best_score", 0))
	]

func _start_preview(song: Dictionary) -> void:
	preview_player.stop()
	preview_is_fading = false
	var music_path := str(song["folder"]) + "/" + str(song.get("music", "music.ogg"))
	if not ResourceLoader.exists(music_path):
		return
	# 每首歌从自己的 song.json 读取试听起点和时长。
	# 没有配置时使用示例默认值，保证旧歌曲仍能试听。
	var preview_data = song.get("preview", {})
	preview_start_time = float(preview_data.get("start", 30.0))
	preview_duration = float(preview_data.get("duration", 15.0))
	preview_fade_in = max(float(preview_data.get("fade_in", 1.0)), 0.0)
	preview_fade_out = max(float(preview_data.get("fade_out", 1.0)), 0.0)
	preview_player.stream = load(music_path)
	preview_end_time = preview_start_time + preview_duration
	preview_player.volume_db = -80.0 if preview_fade_in > 0.0 else 0.0
	preview_player.play(preview_start_time)
	if preview_fade_in > 0.0:
		preview_tween = create_tween()
		preview_tween.tween_property(preview_player, "volume_db", 0.0, preview_fade_in)

func _loop_preview() -> void:
	preview_is_fading = true
	if preview_tween != null:
		preview_tween.kill()
	if preview_fade_out > 0.0:
		preview_tween = create_tween()
		preview_tween.tween_property(preview_player, "volume_db", -80.0, preview_fade_out)
		preview_tween.tween_callback(_restart_preview_segment)
	else:
		_restart_preview_segment()

func _restart_preview_segment() -> void:
	preview_player.stop()
	preview_player.volume_db = -80.0 if preview_fade_in > 0.0 else 0.0
	preview_player.play(preview_start_time)
	preview_is_fading = false
	if preview_fade_in > 0.0:
		preview_tween = create_tween()
		preview_tween.tween_property(preview_player, "volume_db", 0.0, preview_fade_in)

func _on_preview_finished() -> void:
	if preview_player.playing and not preview_is_fading:
		_loop_preview()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_start_game()
	elif event.is_action_pressed("ui_cancel"):
		_back()

func _start_game() -> void:
	if songs.is_empty():
		return
	if preview_tween != null:
		preview_tween.kill()
	preview_player.stop()
	preview_player.volume_db = 0.0
	get_tree().set_meta("selected_song_folder", songs[selected_index]["folder"])
	get_tree().set_meta("selected_song_difficulty", selected_difficulty_key)
	# 设置场景会持续保存 game_settings，这里只负责选择歌曲。
	get_tree().change_scene_to_file("res://main.tscn")

func _back() -> void:
	if preview_player != null:
		if preview_tween != null:
			preview_tween.kill()
		preview_player.stop()
		preview_player.volume_db = 0.0
	get_tree().change_scene_to_file("res://main_menu.tscn")
