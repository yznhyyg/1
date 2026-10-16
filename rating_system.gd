extends RefCounted

# Shared by results, song selection and the home page. Never round before averaging.
const SCORE_POINTS := [700000, 800000, 850000, 900000, 930000, 950000, 970000, 980000, 985000, 990000, 995000, 998000]
const MULTIPLIERS := [0.60, 0.70, 0.80, 0.90, 1.00, 1.10, 1.20, 1.30, 1.35, 1.40, 1.45, 1.50]
const GRADES := ["C", "C+", "B", "B+", "A", "A+", "S", "S+", "SS", "SS+", "SSS", "SSS+"]
const BEST_COUNT := 20

static func constant_for(song: Dictionary) -> float:
	var value = song.get("constant")
	if not (value is float or value is int):
		return 0.0
	var number := float(value)
	if not is_finite(number) or number < 1.0 or number > 10.0:
		return 0.0
	return snappedf(number, 0.1)

static func score_key(song_id: String, difficulty: String = "advanced") -> String:
	var clean_id := song_id.strip_edges()
	var clean_difficulty := difficulty.strip_edges()
	return clean_id if clean_difficulty.is_empty() else "%s::%s" % [clean_id, clean_difficulty]

static func difficulty_data(song: Dictionary, difficulty: String = "advanced") -> Dictionary:
	var difficulties = song.get("difficulties", {})
	if difficulties is Dictionary:
		var item = difficulties.get(difficulty, {})
		if item is Dictionary:
			return item
	return {}

static func constant_for_difficulty(song: Dictionary, difficulty: String = "advanced") -> float:
	var item := difficulty_data(song, difficulty)
	if not item.is_empty():
		return constant_for(item) if item.has("constant") else constant_for(song)
	return constant_for(song)

static func level_text_for_difficulty(song: Dictionary, difficulty: String = "advanced") -> String:
	return level_text({"constant": constant_for_difficulty(song, difficulty)})

static func level_text(song: Dictionary) -> String:
	var constant := constant_for(song)
	if constant <= 0.0:
		return "LV —"
	# Compare integer tenths to avoid floating-point errors at values like 8.7.
	var tenths := roundi(constant * 10.0) % 10
	return "LV %d%s" % [int(constant), "+" if tenths >= 7 else ""]

static func grade_for(score: int) -> String:
	for index in range(SCORE_POINTS.size() - 1, -1, -1):
		if score >= SCORE_POINTS[index]:
			return GRADES[index]
	return "D"

static func song_rating(constant: float, score: int) -> float:
	if not is_finite(constant) or constant < 1.0 or constant > 10.0 or score < SCORE_POINTS[0]:
		return 0.0
	constant = snappedf(constant, 0.1)
	if score >= SCORE_POINTS[-1]:
		return constant * MULTIPLIERS[-1]
	for index in range(SCORE_POINTS.size() - 1):
		if score < SCORE_POINTS[index + 1]:
			var progress := float(score - SCORE_POINTS[index]) / float(SCORE_POINTS[index + 1] - SCORE_POINTS[index])
			return constant * lerpf(MULTIPLIERS[index], MULTIPLIERS[index + 1], progress)
	return 0.0

static func load_catalog() -> Array[Dictionary]:
	var songs: Array[Dictionary] = []
	var directory := DirAccess.open("res://songs")
	if directory == null:
		return songs
	for folder in directory.get_directories():
		var path := "res://songs/" + folder
		var file := FileAccess.open(path + "/song.json", FileAccess.READ)
		if file == null:
			continue
		var song = JSON.parse_string(file.get_as_text())
		if song is Dictionary:
			song["folder"] = path
			songs.append(song)
	return songs

static func personal_rating(songs: Array[Dictionary], scores: Dictionary) -> float:
	var ratings: Array[float] = []
	for song in songs:
		var song_id := str(song.get("folder", "")).get_file()
		if song_id.is_empty():
			continue
		var difficulties = song.get("difficulties", {})
		if difficulties is Dictionary and not difficulties.is_empty():
			for difficulty in difficulties.keys():
				var key := score_key(song_id, str(difficulty))
				var record = scores.get(key, {})
				# Legacy records without a difficulty belong to the advanced chart.
				if str(difficulty) == "advanced" and (not record is Dictionary or record.is_empty()):
					record = scores.get(song_id, {})
				if record is Dictionary:
					ratings.append(song_rating(constant_for_difficulty(song, str(difficulty)), int(record.get("best_score", 0))))
		else:
			var record = scores.get(song_id, {})
			if record is Dictionary:
				ratings.append(song_rating(constant_for(song), int(record.get("best_score", 0))))
	ratings.sort()
	ratings.reverse()
	var total := 0.0
	for index in mini(BEST_COUNT, ratings.size()):
		total += ratings[index]
	return total / float(BEST_COUNT)

static func increase_text(increase: float) -> String:
	var displayed := "%.3f" % maxf(increase, 0.0)
	return "（+0）" if displayed == "0.000" else "（+%s）" % displayed

static func remember_best(scores: Dictionary, result: Dictionary) -> void:
	var song_id := str(result.get("song_id", ""))
	if song_id.is_empty():
		return
	var has_difficulty := result.has("difficulty") or result.has("score_key")
	var difficulty := str(result.get("difficulty", "advanced"))
	var key := str(result.get("score_key", score_key(song_id, difficulty) if has_difficulty else song_id))
	var previous = scores.get(key, {})
	var score := int(result.get("score", 0))
	if previous is Dictionary and int(previous.get("best_score", -1)) > score:
		return
	scores[key] = {
		"song_id": song_id, "difficulty": difficulty, "best_score": score, "grade": grade_for(score),
		"max_combo": int(result.get("max_combo", 0)),
		"perfect_count": int(result.get("perfect", 0)), "great_count": int(result.get("great", 0)),
		"good_count": int(result.get("good", 0)), "miss_count": int(result.get("miss", 0))
	}
