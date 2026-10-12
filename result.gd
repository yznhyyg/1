extends Control

const SupabaseConfig = preload("res://supabase_config.gd")

var data: Dictionary = {}
var rating := "D"
var upload_status: Label
var score_request: HTTPRequest
var request_operation := ""

func _ready() -> void:
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
	upload_status.position = Vector2(110, 515)
	upload_status.size = Vector2(500, 35)
	upload_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(upload_status)

	score_request = HTTPRequest.new()
	add_child(score_request)
	score_request.request_completed.connect(_on_score_request_completed)
	$Continue.grab_focus()
	$Continue.pressed.connect(_continue)
	_check_cloud_best_score()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_ accept") and not $Continue.disabled:
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
	if user_id.is_empty() or song_id.is_empty():
		upload_status.text = "未登录或歌曲编号缺失，成绩仅保存在本次游戏中"
		return

	# 旧纪录已经在登录时加载到内存，无需在结算页再次请求服务器。
	var cached = get_tree().get_meta("song_scores", {})
	if cached is Dictionary and cached.has(song_id):
		var old_record = cached[song_id]
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
		"song_id": str(data.get("song_id", "")),
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
	if message == "成绩已上传":
		var cached = get_tree().get_meta("song_scores", {})
		if not cached is Dictionary:
			cached = {}
		cached[str(data.get("song_id", ""))] = {
			"song_id": str(data.get("song_id", "")),
			"best_score": int(data.get("score", 0)),
			"grade": rating,
			"max_combo": int(data.get("max_combo", 0)),
			"perfect_count": int(data.get("perfect", 0)),
			"great_count": int(data.get("great", 0)),
			"good_count": int(data.get("good", 0)),
			"miss_count": int(data.get("miss", 0))
		}
		get_tree().set_meta("song_scores", cached)
	upload_status.text = message
	$Continue.disabled = false
	$Continue.grab_focus()

func _rating_for_score(value: int) -> String:
	if value >= 998000: return "SSS+"
	if value >= 995000: return "SSS"
	if value >= 990000: return "SS+"
	if value >= 985000: return "SS"
	if value >= 980000: return "S+"
	if value >= 970000: return "S"
	if value >= 950000: return "A+"
	if value >= 930000: return "A"
	if value >= 900000: return "B+"
	if value >= 850000: return "B"
	if value >= 800000: return "C+"
	if value >= 700000: return "C"
	return "D"
