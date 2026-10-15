extends Control

const RatingSystem = preload("res://rating_system.gd")
const PartnerSystem = preload("res://partner_system.gd")

const UI = preload("res://ui/rhythm_ui.gd")
const Brand = preload("res://ui/brand.gd")
const EntryBackdrop = preload("res://ui/entry_backdrop.gd")

const SupabaseConfig = preload("res://supabase_config.gd")
const SESSION_FILE := "user://supabase_session.json"

var email_input: LineEdit
var password_input: LineEdit
var message_label: Label
var request: HTTPRequest
var busy := false
var auth_operation := ""
var bootstrap_user_id := ""
var bootstrap_access_token := ""
var settings_fallback_attempted := false

func _ready() -> void:
	UI.setup(self)
	# The entry screen gets its own restrained backdrop: it keeps the rhythm-game
	# identity while leaving the login card and text easy to read.
	var default_backdrop := get_child(0)
	if default_backdrop is Control:
		default_backdrop.hide()
	var entry_backdrop := EntryBackdrop.new()
	entry_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	entry_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(entry_backdrop)
	move_child(entry_backdrop, 0)

	UI.card(self, Rect2(56, 330, 608, 520))
	UI.label(self, "THETALE  /  RHYTHM GAME", Rect2(56, 66, 608, 40), 17, UI.CYAN)
	UI.label(self, "每一次敲击，都与节奏共鸣。", Rect2(56, 254, 608, 40), 22, UI.MUTED)
	UI.label(self, "欢迎回来", Rect2(88, 356, 544, 45), 28)
	UI.label(self, "邮箱", Rect2(88, 428, 544, 30), 18, UI.MUTED)
	UI.label(self, "密码", Rect2(88, 544, 544, 30), 18, UI.MUTED)
	UI.reveal(self)
	Brand.title(self, "Thetale", Rect2(56, 138, 608, 92), 70)
	Brand.accent_line(self, Rect2(294, 232, 132, 3))

	email_input = LineEdit.new()
	email_input.placeholder_text = "邮箱"
	email_input.position = Vector2(88, 468)
	email_input.size = Vector2(544, 64)
	email_input.text = ""
	add_child(email_input)

	password_input = LineEdit.new()
	password_input.placeholder_text = "密码"
	password_input.secret = true
	password_input.position = Vector2(88, 584)
	password_input.size = Vector2(544, 64)
	add_child(password_input)

	var login_button := Button.new()
	login_button.text = "登录"
	login_button.position = Vector2(88, 698)
	login_button.size = Vector2(262, 68)
	UI.primary(login_button)
	login_button.pressed.connect(_login)
	add_child(login_button)

	var register_button := Button.new()
	register_button.text = "注册账号"
	register_button.position = Vector2(370, 698)
	register_button.size = Vector2(262, 68)
	register_button.pressed.connect(_register)
	add_child(register_button)

	message_label = Label.new()
	message_label.position = Vector2(88, 876)
	message_label.size = Vector2(544, 96)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.text = "登录账号，同步成绩与游戏设置"
	message_label.add_theme_color_override("font_color", UI.MUTED)
	message_label.add_theme_font_size_override("font_size", 18)
	add_child(message_label)

	request = HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(_on_request_completed)
	email_input.grab_focus()
	_try_restore_session()

func _login() -> void:
	_auth_request("/auth/v1/token?grant_type=password", "login")

func _register() -> void:
	_auth_request("/auth/v1/signup", "register")

func _auth_request(path: String, operation: String) -> void:
	if busy:
		return
	var email := email_input.text.strip_edges()
	var password := password_input.text
	if email.is_empty() or password.length() < 6:
		message_label.text = "请输入邮箱，密码至少需要 6 位。"
		return
	if SupabaseConfig.PUBLISHABLE_KEY.begins_with("请把"):
		message_label.text = "请先在 supabase_config.gd 中填写公开密钥。"
		return
	busy = true
	auth_operation = operation
	message_label.text = "正在连接服务器……"
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"apikey: " + SupabaseConfig.PUBLISHABLE_KEY
	])
	var body := JSON.stringify({"email": email, "password": password})
	var error := request.request(SupabaseConfig.PROJECT_URL + path, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		busy = false
		auth_operation = ""
		message_label.text = "无法连接登录服务器，请检查网络。"

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	busy = false
	var operation := auth_operation
	auth_operation = ""
	var text := body.get_string_from_utf8()
	var data = JSON.parse_string(text)

	# 登录后的设置读取也是一次网络请求，需要和登录响应分开处理。
	if operation == "load_settings":
		_finish_cloud_settings_load(result, response_code, data)
		return
	if operation == "load_scores":
		_finish_cloud_scores_load(result, response_code, data)
		return
	if operation == "track_login":
		_finish_login_day_track(result, response_code)
		return

	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		if operation == "restore":
			# 只有服务器明确拒绝刷新令牌时才删除；断网和服务器故障不删。
			if result == HTTPRequest.RESULT_SUCCESS and response_code >= 400 and response_code < 500:
				_clear_saved_session()
				message_label.text = "上次登录已失效，请重新登录。"
			else:
				message_label.text = "暂时无法恢复登录，请检查网络后重试。"
			return
		var error_message := "登录失败，请检查邮箱和密码。"
		if data is Dictionary:
			error_message = str(data.get("msg", data.get("error_description", error_message)))
		message_label.text = error_message
		return
	if data is Dictionary and data.has("access_token"):
		_save_refresh_token(str(data.get("refresh_token", "")))
		get_tree().set_meta("supabase_session", data)
		_load_cloud_settings_after_login(data)
	else:
		message_label.text = "注册成功，请检查邮箱后再登录。"

func _load_cloud_settings_after_login(session: Dictionary) -> void:
	# 云端没有记录或暂时读取失败时使用这一组默认值。
	get_tree().set_meta("game_settings", {
		"note_speed": 1.0,
		"artwork_brightness": 0.65,
		"chart_offset": 0.0,
		"login_days": 0,
		"last_login_date": ""
	})

	var user = session.get("user", {})
	var user_id := str(user.get("id", "")) if user is Dictionary else ""
	var access_token := str(session.get("access_token", ""))
	if user_id.is_empty() or access_token.is_empty():
		_start_main_menu()
		return

	bootstrap_user_id = user_id
	bootstrap_access_token = access_token
	busy = true
	auth_operation = "load_settings"
	settings_fallback_attempted = false
	message_label.text = "登录成功，正在读取云端设置……"
	_request_cloud_settings(true)

func _request_cloud_settings(include_login_fields: bool) -> void:
	var headers := PackedStringArray([
		"apikey: " + SupabaseConfig.PUBLISHABLE_KEY,
		"Authorization: Bearer " + bootstrap_access_token
	])
	var select_fields := "note_speed,artwork_brightness,chart_offset"
	if include_login_fields:
		select_fields += ",login_days,last_login_date"
	var url := SupabaseConfig.PROJECT_URL + "/rest/v1/player_settings"
	url += "?user_id=eq." + bootstrap_user_id
	url += "&select=" + select_fields + "&limit=1"
	var error := request.request(url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		if include_login_fields and not settings_fallback_attempted:
			settings_fallback_attempted = true
			busy = true
			auth_operation = "load_settings"
			_request_cloud_settings(false)
		else:
			busy = false
			auth_operation = ""
			_load_cloud_scores_after_settings()

func _finish_cloud_settings_load(result: int, response_code: int, response) -> void:
	var succeeded := result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300
	if not succeeded and not settings_fallback_attempted:
		settings_fallback_attempted = true
		busy = true
		auth_operation = "load_settings"
		_request_cloud_settings(false)
		return
	if succeeded and response is Array and not response.is_empty() and response[0] is Dictionary:
		var cloud: Dictionary = response[0]
		get_tree().set_meta("game_settings", {
			"note_speed": clampf(float(cloud.get("note_speed", 1.0)), 0.1, 12.0),
			"artwork_brightness": clampf(float(cloud.get("artwork_brightness", 0.65)), 0.0, 1.0),
			"chart_offset": clampf(float(cloud.get("chart_offset", 0.0)), -0.5, 0.5),
			"login_days": maxi(int(cloud.get("login_days", 0)), 0),
			"last_login_date": str(cloud.get("last_login_date", ""))
		})
	elif not succeeded:
		print("登录后读取云端设置失败：", response_code)
	_track_login_day()

func _track_login_day() -> void:
	var settings = get_tree().get_meta("game_settings", {})
	if not settings is Dictionary:
		settings = {}
	var today := Time.get_date_string_from_system()
	var current_days := maxi(int(settings.get("login_days", 0)), 0)
	var last_date := str(settings.get("last_login_date", ""))
	if last_date == today:
		PartnerSystem.grant_login_day_rewards(get_tree(), current_days)
		_load_cloud_scores_after_settings()
		return
	var updated_days := current_days + 1
	get_tree().set_meta("game_settings", {
		"note_speed": float(settings.get("note_speed", 1.0)),
		"artwork_brightness": float(settings.get("artwork_brightness", 0.65)),
		"chart_offset": float(settings.get("chart_offset", 0.0)),
		"login_days": updated_days,
		"last_login_date": today
	})
	busy = true
	auth_operation = "track_login"
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"apikey: " + SupabaseConfig.PUBLISHABLE_KEY,
		"Authorization: Bearer " + bootstrap_access_token,
		"Prefer: resolution=merge-duplicates,return=minimal"
	])
	var url := SupabaseConfig.PROJECT_URL + "/rest/v1/player_settings?on_conflict=user_id"
	var body := JSON.stringify({
		"user_id": bootstrap_user_id,
		"login_days": updated_days,
		"last_login_date": today
	})
	var error := request.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		busy = false
		auth_operation = ""
		_load_cloud_scores_after_settings()

func _finish_login_day_track(result: int, response_code: int) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		print("登录天数保存失败：", response_code)
	else:
		var settings = get_tree().get_meta("game_settings", {})
		var login_days := int(settings.get("login_days", 0)) if settings is Dictionary else 0
		PartnerSystem.grant_login_day_rewards(get_tree(), login_days)
	_load_cloud_scores_after_settings()

func _load_cloud_scores_after_settings() -> void:
	if bootstrap_user_id.is_empty() or bootstrap_access_token.is_empty():
		get_tree().set_meta("song_scores", {})
		_start_main_menu()
		return
	busy = true
	auth_operation = "load_scores"
	message_label.text = "正在加载歌曲成绩……"
	var headers := PackedStringArray([
		"apikey: " + SupabaseConfig.PUBLISHABLE_KEY,
		"Authorization: Bearer " + bootstrap_access_token
	])
	var url := SupabaseConfig.PROJECT_URL + "/rest/v1/song_scores"
	url += "?user_id=eq." + bootstrap_user_id
	url += "&select=song_id,best_score,grade,max_combo,perfect_count,great_count,good_count,miss_count"
	var error := request.request(url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		busy = false
		auth_operation = ""
		get_tree().set_meta("song_scores", {})
		_start_main_menu()

func _finish_cloud_scores_load(result: int, response_code: int, response) -> void:
	var scores_by_song: Dictionary = {}
	var succeeded := result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300
	if succeeded and response is Array:
		for item in response:
			if item is Dictionary:
				scores_by_song[str(item.get("song_id", ""))] = item
	else:
		print("登录时读取歌曲成绩失败：", response_code)
	get_tree().set_meta("song_scores", scores_by_song)
	_start_main_menu()

func _start_main_menu() -> void:
	PartnerSystem.grant_starter(get_tree())
	# 初始化本地角色档案后，再按云端登录天数发放奖励。
	var settings = get_tree().get_meta("game_settings", {})
	if settings is Dictionary:
		PartnerSystem.grant_login_day_rewards(get_tree(), int(settings.get("login_days", 0)))
	var scores = get_tree().get_meta("song_scores", {})
	if scores is Dictionary:
		PartnerSystem.grant_score_rewards(get_tree(), scores)
	_load_local_song_catalog()
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _load_local_song_catalog() -> void:
	get_tree().set_meta("song_catalog", RatingSystem.load_catalog())

func _try_restore_session() -> void:
	if not FileAccess.file_exists(SESSION_FILE):
		return
	var file := FileAccess.open(SESSION_FILE, FileAccess.READ)
	if file == null:
		return
	var saved = JSON.parse_string(file.get_as_text())
	if not (saved is Dictionary):
		_clear_saved_session()
		return
	var refresh_token := str(saved.get("refresh_token", ""))
	if refresh_token.is_empty():
		_clear_saved_session()
		return

	# 不直接复用可能已经过期的 access_token，而是向 Supabase 换取新会话。
	busy = true
	auth_operation = "restore"
	message_label.text = "正在恢复上次登录……"
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"apikey: " + SupabaseConfig.PUBLISHABLE_KEY
	])
	var body := JSON.stringify({"refresh_token": refresh_token})
	var url := SupabaseConfig.PROJECT_URL + "/auth/v1/token?grant_type=refresh_token"
	var error := request.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		busy = false
		auth_operation = ""
		message_label.text = "暂时无法恢复登录，请检查网络后重试。"

func _save_refresh_token(refresh_token: String) -> void:
	if refresh_token.is_empty():
		return
	var file := FileAccess.open(SESSION_FILE, FileAccess.WRITE)
	if file == null:
		push_warning("无法保存登录状态：" + SESSION_FILE)
		return
	# 本地只保存刷新令牌，不保存邮箱和原始密码。
	file.store_string(JSON.stringify({"refresh_token": refresh_token}))

func _clear_saved_session() -> void:
	if FileAccess.file_exists(SESSION_FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SESSION_FILE))
