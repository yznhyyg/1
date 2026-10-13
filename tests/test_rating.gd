extends SceneTree

const RatingSystem = preload("res://rating_system.gd")
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func near(actual: float, expected: float, message: String) -> void:
	check(absf(actual - expected) < 0.0000001, "%s: got %.9f, expected %.9f" % [message, actual, expected])

func run() -> void:
	# Independent values from the specified rules, including both sides of boundaries.
	var points := [700000, 800000, 850000, 900000, 930000, 950000, 970000, 980000, 985000, 990000, 995000, 998000]
	var factors := [0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.35, 1.4, 1.45, 1.5]
	var grades := ["C", "C+", "B", "B+", "A", "A+", "S", "S+", "SS", "SS+", "SSS", "SSS+"]
	for index in points.size():
		near(RatingSystem.song_rating(9.5, points[index]), 9.5 * factors[index], "boundary %d" % points[index])
		check(RatingSystem.grade_for(points[index]) == grades[index], "grade boundary")
		if index < points.size() - 1:
			var midpoint: int = (points[index] + points[index + 1]) / 2
			near(RatingSystem.song_rating(9.5, midpoint), 9.5 * (factors[index] + factors[index + 1]) / 2.0, "midpoint")
			near(RatingSystem.song_rating(9.5, points[index + 1] - 1), 9.5 * (factors[index + 1] - (factors[index + 1] - factors[index]) / float(points[index + 1] - points[index])), "one point below upper boundary")
	near(RatingSystem.song_rating(9.5, 995000), 13.775, "user example lower end")
	near(RatingSystem.song_rating(9.5, 996500), 14.0125, "user example midpoint")
	for score in [998000, 999999, 1000000, 1100000]:
		near(RatingSystem.song_rating(9.5, score), 14.25, "cap")
	for score in [-1, 0, 699999]:
		near(RatingSystem.song_rating(9.5, score), 0.0, "D excluded")
		check(RatingSystem.grade_for(score) == "D", "D grade")
	for value in [null, "9.5", 0.0, 0.9, 10.1, INF, NAN]:
		near(RatingSystem.constant_for({"constant": value}), 0.0, "invalid or unset constant")
	check(RatingSystem.level_text({"constant": 9.5}) == "LV 9.5", "one decimal display")
	near(RatingSystem.song_rating(1.0, 998000), 1.5, "minimum level")
	near(RatingSystem.song_rating(10.0, 998000), 15.0, "maximum level")
	near(RatingSystem.personal_rating([], {}), 0.0, "empty library")
	var catalog: Array[Dictionary] = [{"folder": "res://songs/a", "constant": 9.5}, {"folder": "res://songs/b", "constant": 10.0}]
	var scores := {"a": {"best_score": 995000}, "b": {"best_score": 998000}, "unknown": {"best_score": 1000000}}
	near(RatingSystem.personal_rating(catalog, scores), 1.43875, "two songs divided by 20, without premature rounding")
	catalog.append(catalog[0])
	near(RatingSystem.personal_rating(catalog, scores), 1.43875, "same song cannot occupy two slots")
	catalog.clear()
	scores.clear()
	for index in 25:
		var id := "song%d" % index
		catalog.append({"folder": "res://songs/" + id, "constant": 1.0 + index * 0.1})
		scores[id] = {"best_score": 998000}
	near(RatingSystem.personal_rating(catalog, scores), 3.675, "highest 20 of 25, sorted by rating")
	var best: Dictionary = {}
	RatingSystem.remember_best(best, {"song_id": "a", "score": 998000})
	RatingSystem.remember_best(best, {"song_id": "a", "score": 700000})
	check(best.size() == 1 and best["a"]["best_score"] == 998000, "lower result preserves highest score")
	RatingSystem.remember_best(best, {"song_id": "a", "score": 1000000})
	check(best["a"]["best_score"] == 1000000, "new personal best")

	# Exercise actual result -> song selection -> home presentation without cloud credentials.
	set_meta("song_scores", {"leisure": {"best_score": 990000}})
	set_meta("result_data", {"song_id": "leisure", "score": 995000})
	var result = load("res://result.tscn").instantiate()
	root.add_child(result)
	await process_frame
	check(get_meta("song_scores")["leisure"]["best_score"] == 995000, "result updates session best even without cloud upload")
	check(result.song_rating_label.text.contains("个人 RATING"), "result rating display")
	check(not result.get_node("Continue").disabled, "offline continue remains available")
	result.queue_free()
	await process_frame
	var selection = load("res://song_select.tscn").instantiate()
	root.add_child(selection)
	await process_frame
	var selected := -1
	for index in selection.songs.size():
		if str(selection.songs[index]["folder"]).get_file() == "leisure":
			selected = index
	check(selected >= 0, "song catalog contains leisure")
	if selected >= 0:
		selection._select_song(selected)
		var song: Dictionary = selection.songs[selected]
		check(selection.level_label.text == RatingSystem.level_text(song), "song level display")
		var constant := RatingSystem.constant_for(song)
		var expected := "RATING %.3f" % RatingSystem.song_rating(constant, 995000) if constant > 0.0 else "定数待设置"
		check(selection.track_rating_label.text == expected, "best rating on selection page")
	selection.queue_free()
	await process_frame
	var home = load("res://main_menu.tscn").instantiate()
	root.add_child(home)
	await process_frame
	var expected_home := RatingSystem.personal_rating(RatingSystem.load_catalog(), get_meta("song_scores"))
	check(home.personal_rating_label.text == "%.3f" % expected_home, "home recalculates from best scores and current constants")
	home.queue_free()
	await process_frame
	print("Rating tests: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)
