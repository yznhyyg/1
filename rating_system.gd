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
	var seen: Dictionary = {}
	for song in songs:
		var song_id := str(song.get("folder", "")).get_file()
		if song_id.is_empty() or seen.has(song_id):
			continue
		seen[song_id] = true
		var record = scores.get(song_id, {})
		if record is Dictionary:
			ratings.append(song_rating(constant_for(song), int(record.get("best_score", 0))))
	ratings.sort()
	ratings.reverse()
	var total := 0.0
	for index in mini(BEST_COUNT, ratings.size()):
		total += ratings[index]
	return total / float(BEST_COUNT)

static func remember_best(scores: Dictionary, result: Dictionary) -> void:
	var song_id := str(result.get("song_id", ""))
	if song_id.is_empty():
		return
	var previous = scores.get(song_id, {})
	var score := int(result.get("score", 0))
	if previous is Dictionary and int(previous.get("best_score", -1)) > score:
		return
	scores[song_id] = {
		"song_id": song_id, "best_score": score, "grade": grade_for(score),
		"max_combo": int(result.get("max_combo", 0)),
		"perfect_count": int(result.get("perfect", 0)), "great_count": int(result.get("great", 0)),
		"good_count": int(result.get("good", 0)), "miss_count": int(result.get("miss", 0))
	}
