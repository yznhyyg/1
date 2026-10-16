extends Control

const RatingSystem = preload("res://rating_system.gd")
const Partners = preload("res://partner_system.gd")

const UI = preload("res://ui/rhythm_ui.gd")

const SupabaseConfig = preload("res://supabase_config.gd")

var data: Dictionary = {}
var rating := "D"
var song_rating_label: Label
var personal_rating_label: Label
var rating_increase_label: Label
var rating_before := 0.0
var rating_after := 0.0
var rating_increase := 0.0
var upload_status: Label
var score_request: HTTPRequest
var request_operation := ""
var reward_label: Label

func _ready() -> void:
	$Background.hide()
	UI.setup(self)
	UI.card(self, Rect2(40, 210, 640, 740))
	move_child(get_child(get_child_count() - 1), 1)
	UI.label(self, "SESSION COMPLETE", Rect2(56, 50, 608, 40), 16, UI.CYAN)
	UI.reveal(self)
	data = get_tree().get_meta("result_data", {})
	rating = _rating_for_score(int(data.get("score", 0)))
	$Rating.text = rating
	$Details.text = "分数：%d\n\nPerfect：%d    Great：%d\nGood：%d    Miss：%d\n\n最大 Combo：%d" % [
		int(data.get("score", 0)),
		int(data.get("perfect", 0)),
		int(data.get("great", 0)),
		int(data.get("good", 0)),
		int(data.get("miss", 0)),
		int(data.get("max_combo", 0))
	]
	upload_status = Label.new()
	upload_status.position = Vector2(64, 978)
	upload_status.size = Vector2(592, 80)
	upload_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upload_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	upload_status.add_theme_font_size_override("font_size", 18)
	upload_status.add_theme_color_override("font_color", UI.MUTED)
	add_child(upload_status)

	score_request = HTTPRequest.new()
	add_child(score_request)
	score_request.request_completed.connect(_on_score_request_completed)
	UI.primary($Continue)
	$Continue.grab_focus()
	$Continue.pressed.connect(_continue)
	# Check the previous cloud record before updating this session's best score.
	_check_cloud_best_score()
	var cached = get_tree().get_meta("song_scores", {})
	if not cached is Dictionary:
		cached = {}
	var songs := RatingSystem.load_catalog()
	rating_before = RatingSystem.personal_rating(songs, cached)
	RatingSystem.remember_best(cached, data)
	get_tree().set_meta("song_scores", cached)
	var rewards := Partners.grant_score_rewards(get_tree(), cached)
	if not rewards.is_empty():
		var names: PackedStringArray = []
		for character in rewards:
			names.append(str(character.get("name", character["id"])))
		reward_label = UI.label(self, "新伙伴已获得 · %s\n可在主页「角色」中设为上场" % "、".join(names), Rect2(64, 1064, 592, 60), 18, Color("#E7B87D"))
		reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rating_after = RatingSystem.personal_rating(songs, cached)
	rating_increase = maxf(rating_after - rating_before, 0.0)
	var constant := 0.0
	var difficulty_id := str(data.get("difficulty", "advanced"))
	for song in songs:
		if str(song.get("folder", "")).get_file() == str(data.get("song_id", "")):
			constant = RatingSystem.constant_for_difficulty(song, difficulty_id)
			break
	song_rating_label = UI.label(self, "%s · %s" % [RatingSystem.level_text({"constant": constant}), difficulty_id], Rect2(64, 765, 592, 38), 22, UI.CYAN)
	song_rating_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var heading := UI.label(self, "RATING", Rect2(64, 808, 592, 28), 18, UI.MUTED)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var rating_row := HBoxContainer.new()
	rating_row.position = Vector2(64, 841)
	rating_row.size = Vector2(592, 72)
	rating_row.alignment = BoxContainer.ALIGNMENT_CENTER
	rating_row.add_theme_constant_override("separation", 12)
	rating_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rating_row)
	personal_rating_label = UI.label(rating_row, "%.3f" % rating_after, Rect2(), 44, Color("#FF75BC"))
	personal_rating_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rating_increase_label = UI.label(rating_row, RatingSystem.increase_text(rating_increase), Rect2(), 24, UI.CYAN)
	rating_increase_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not $Continue.disabled:
		_continue()

func _continue() -> void:
	get_tree().change_scene_to_file("res://song_select.tscn")

func _get_session() -> Dictionary:
	var session = get_tree().get_meta("supabase_session", {})
	return session if session is Dictionary else {}

func _get_user_id() -> String:
	var user = _get_session().get("user", {})
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

func _check_cloud_best_score() -> void:
	var user_id := _get_user_id()
	var song_id := str(data.get("song_id", ""))
	var score_key := str(data.get("score_key", RatingSystem.score_key(song_id, str(data.get("difficulty", "advanced")))))
	if user_id.is_empty() or song_id.is_empty():
		upload_status.text = "未登录或歌曲编号缺失，成绩仅保存在本次游戏中"
		return

	# 旧纪录已经在登录时加载到内存，无需在结算页再次请求服务器。
	var cached = get_tree().get_meta("song_scores", {})
	if cached is Dictionary and (cached.has(score_key) or (str(data.get("difficulty", "advanced")) == "advanced" and cached.has(song_id))):
		var old_record = cached[score_key] if cached.has(score_key) else cached[song_id]
		if old_record is Dictionary:
			var old_score := int(old_record.get("best_score", 0))
			if old_score > int(data.get("score", 0)):
				_finish_upload("本次未打破云端最高分：%d" % old_score)
				return
	upload_status.text = "正在上传新纪录……"
	$Continue.disabled = true
	_upload_score()

func _upload_score() -> void:
	request_operation = "upload"
	var headers := _cloud_headers(true)
	headers.append("Prefer: resolution=merge-duplicates,return=minimal")
	var body := {
		"user_id": _get_user_id(),
		"song_id": str(data.get("score_key", RatingSystem.score_key(str(data.get("song_id", "")), str(data.get("difficulty", "advanced"))))),
		"best_score": int(data.get("score", 0)),
		"max_combo": int(data.get("max_combo", 0)),
		"perfect_count": int(data.get("perfect", 0)),
		"great_count": int(data.get("great", 0)),
		"good_count": int(data.get("good", 0)),
		"miss_count": int(data.get("miss", 0)),
		"grade": rating,
		"updated_at": Time.get_datetime_string_from_system(true)
	}
	var url := SupabaseConfig.PROJECT_URL + "/rest/v1/song_scores?on_conflict=user_id,song_id"
	var error := score_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if error != OK:
		_finish_upload("成绩上传失败，请检查网络")

func _on_score_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var operation := request_operation
	request_operation = ""
	var succeeded := result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300
	if not succeeded:
		print("Supabase 成绩同步失败：", response_code, " ", body.get_string_from_utf8())
		_finish_upload("成绩上传失败，请检查数据库权限")
		return

	if operation == "upload":
		_finish_upload("成绩已上传")
		return

func _finish_upload(message: String) -> void:
	upload_status.text = message
	$Continue.disabled = false
	$Continue.grab_focus()

func _rating_for_score(value: int) -> String:
	return RatingSystem.grade_for(value)
