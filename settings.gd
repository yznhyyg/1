extends Control

const UI = preload("res://ui/rhythm_ui.gd")

const SupabaseConfig = preload("res://supabase_config.gd")

var speed: float = 1.0
var brightness: float = 0.65
var offset: float = 0.0
var speed_value: Label
var brightness_value: Label
var offset_value: Label
var speed_slider: HSlider
var brightness_slider: HSlider
var offset_slider: HSlider
var status_label: Label
var finish_button: Button
var cloud_request: HTTPRequest
var cloud_operation := ""

func _ready() -> void:
	var saved: Dictionary = get_tree().get_meta("game_settings", {})
	speed = float(saved.get("note_speed", 1.0))
	brightness = float(saved.get("artwork_brightness", 0.65))
	offset = float(saved.get("chart_offset", 0.0))
	UI.setup(self)
	UI.label(self, "PERSONALIZE / 设置", Rect2(40, 30, 640, 35), 16, UI.CYAN)
	for y in [160, 350, 540]:
		UI.card(self, Rect2(32, y, 656, 160))
	UI.label(self, "找到最适合你的手感。", Rect2(40, 755, 640, 40), 24, UI.MUTED)
	UI.label(self, "流速影响音符移动速度；延迟用于校准听感与判定。", Rect2(40, 813, 640, 40), 18, UI.MUTED)
	UI.reveal(self)
	var title := Label.new()
	title.text = "游戏设置"
	title.position = Vector2(0, 70)
	title.size = Vector2(720, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	add_child(title)
	_add_speed_control()
	_add_slider("背景亮度", 380, brightness, 0.0, 1.0, 0.01, _brightness_changed, "brightness")
	_add_slider("谱面延迟（秒）", 570, offset, -0.5, 0.5, 0.01, _offset_changed, "offset")
	status_label = Label.new()
	# 720 像素竖屏中居中显示，旧坐标会让文字跑出屏幕右侧。
	status_label.position = Vector2(60, 1095)
	status_label.size = Vector2(600, 40)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color("#8B93A7"))
	status_label.add_theme_font_size_override("font_size", 15)
	add_child(status_label)
	finish_button = Button.new()
	finish_button.text = "保存并返回"
	# 与选曲页主按钮使用相同边距，固定在竖屏底部。
	finish_button.position = Vector2(32, 1165)
	finish_button.size = Vector2(656, 76)
	finish_button.add_theme_font_size_override("font_size", 21)
	finish_button.add_theme_color_override("font_color", Color.WHITE)
	finish_button.add_theme_color_override("font_hover_color", Color.WHITE)
	UI.primary(finish_button)
	finish_button.pressed.connect(_finish)
	add_child(finish_button)

	# HTTPRequest 负责和 Supabase 的 player_settings 表通信。
	cloud_request = HTTPRequest.new()
	add_child(cloud_request)
	cloud_request.request_completed.connect(_on_cloud_request_completed)
	status_label.text = "已使用登录时加载的云端设置"


func _add_speed_control() -> void:
	var label := Label.new()
	label.text = "音符流速"
	label.position = Vector2(56, 180)
	label.size = Vector2(180, 45)
	label.add_theme_font_size_override("font_size", 24)
	add_child(label)
	var minus := Button.new()
	minus.text = "-"
	minus.position = Vector2(56, 244)
	minus.size = Vector2(55, 50)
	minus.pressed.connect(func(): _change_speed(-0.1))
	add_child(minus)
	speed_value = Label.new()
	speed_value.position = Vector2(122, 249)
	speed_value.size = Vector2(120, 40)
	speed_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(speed_value)
	var plus := Button.new()
	plus.text = "+"
	plus.position = Vector2(245, 244)
	plus.size = Vector2(55, 50)
	plus.pressed.connect(func(): _change_speed(0.1))
	add_child(plus)
	speed_slider = HSlider.new()
	speed_slider.position = Vector2(330, 254)
	speed_slider.size = Vector2(326, 30)
	speed_slider.min_value = 0.1
	speed_slider.max_value = 12.0
	speed_slider.step = 0.1
	speed_slider.value = speed
	speed_slider.value_changed.connect(_speed_changed)
	add_child(speed_slider)
	_update_speed_text()

func _add_slider(caption: String, y: float, value: float, min_value: float, max_value: float, step: float, callback: Callable, kind: String) -> void:
	var label := Label.new()
	label.text = caption
	label.position = Vector2(56, y)
	label.size = Vector2(220, 40)
	label.add_theme_font_size_override("font_size", 24)
	add_child(label)
	var slider := HSlider.new()
	slider.position = Vector2(56, y + 64)
	slider.size = Vector2(600, 30)
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = value
	slider.value_changed.connect(callback)
	add_child(slider)
	var value_label := Label.new()
	value_label.position = Vector2(516, y)
	value_label.size = Vector2(140, 40)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_color_override("font_color", UI.CYAN)
	add_child(value_label)
	if kind == "brightness": brightness_value = value_label
	else: offset_value = value_label
	if kind == "brightness": brightness_slider = slider
	else: offset_slider = slider
	callback.call(value)

func _change_speed(amount: float) -> void:
	speed = clampf(snapped(speed + amount, 0.1), 0.1, 12.0)
	if speed_slider:
		speed_slider.value = speed
	_update_speed_text()

func _speed_changed(value: float) -> void:
	speed = clampf(value, 0.1, 12.0)
	_update_speed_text()

func _update_speed_text() -> void:
	if speed_value: speed_value.text = "%.1f" % speed

func _brightness_changed(value: float) -> void:
	brightness = value
	if brightness_value: brightness_value.text = "%.2f" % brightness

func _offset_changed(value: float) -> void:
	offset = value
	if offset_value: offset_value.text = "%+.2f s" % offset

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_finish()

func _finish() -> void:
	# 先让设置立即在本次游戏中生效，再尝试保存到云端。
	var settings := {
		"note_speed": speed,
		"artwork_brightness": brightness,
		"chart_offset": offset
	}
	get_tree().set_meta("game_settings", settings)
	# 玩家可能在读取结束前就点击完成，先取消旧请求再保存。
	if cloud_operation == "load":
		cloud_request.cancel_request()
		cloud_operation = ""
	_save_cloud_settings(settings)

func _get_session() -> Dictionary:
	var session = get_tree().get_meta("supabase_session", {})
	return session if session is Dictionary else {}

func _get_user_id() -> String:
	var session := _get_session()
	var user = session.get("user", {})
	if user is Dictionary:
		return str(user.get("id", ""))
	return ""

func _cloud_headers(include_json: bool = false) -> PackedStringArray:
	var session := _get_session()
	var headers := PackedStringArray([
		"apikey: " + SupabaseConfig.PUBLISHABLE_KEY,
		"Authorization: Bearer " + str(session.get("access_token", ""))
	])
	if include_json:
		headers.append("Content-Type: application/json")
	return headers

func _load_cloud_settings() -> void:
	var user_id := _get_user_id()
	if user_id.is_empty():
		status_label.text = "没有登录信息，当前使用本地设置"
		return
	cloud_operation = "load"
	status_label.text = "正在读取云端设置……"
	var url := SupabaseConfig.PROJECT_URL + "/rest/v1/player_settings?user_id=eq." + user_id
	url += "&select=note_speed,artwork_brightness,chart_offset"
	var error := cloud_request.request(url, _cloud_headers(), HTTPClient.METHOD_GET)
	if error != OK:
		cloud_operation = ""
		status_label.text = "云端连接失败，当前使用本地设置"

func _save_cloud_settings(settings: Dictionary) -> void:
	var user_id := _get_user_id()
	if user_id.is_empty():
		get_tree().change_scene_to_file("res://song_select.tscn")
		return
	cloud_operation = "save"
	status_label.text = "正在保存到云端……"
	finish_button.disabled = true
	var headers := _cloud_headers(true)
	# 使用 user_id 主键合并数据：第一次是新增，以后是更新。
	headers.append("Prefer: resolution=merge-duplicates,return=minimal")
	var body := settings.duplicate()
	body["user_id"] = user_id
	var url := SupabaseConfig.PROJECT_URL + "/rest/v1/player_settings?on_conflict=user_id"
	var error := cloud_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if error != OK:
		get_tree().change_scene_to_file("res://song_select.tscn")

func _on_cloud_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var operation := cloud_operation
	cloud_operation = ""
	var succeeded := result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300

	if operation == "save":
		# 网络失败时本地设置依然有效，不能把玩家困在设置页面。
		get_tree().change_scene_to_file("res://song_select.tscn")
		return

	if operation != "load":
		return
	if not succeeded:
		status_label.text = "读取云端设置失败，当前使用本地设置"
		print("读取 Supabase 设置失败：", response_code, " ", body.get_string_from_utf8())
		return

	var data = JSON.parse_string(body.get_string_from_utf8())
	if not (data is Array) or data.is_empty():
		status_label.text = "云端暂无设置，点完成后会自动创建"
		return
	if not (data[0] is Dictionary):
		status_label.text = "云端设置格式不正确，当前使用本地设置"
		return

	var cloud: Dictionary = data[0]
	speed = clampf(float(cloud.get("note_speed", speed)), 0.1, 12.0)
	brightness = clampf(float(cloud.get("artwork_brightness", brightness)), 0.0, 1.0)
	offset = clampf(float(cloud.get("chart_offset", offset)), -0.5, 0.5)
	speed_slider.value = speed
	brightness_slider.value = brightness
	offset_slider.value = offset
	get_tree().set_meta("game_settings", {
		"note_speed": speed,
		"artwork_brightness": brightness,
		"chart_offset": offset
	})
	status_label.text = "已读取云端设置"
