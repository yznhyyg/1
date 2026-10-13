extends SceneTree

const Partners = preload("res://partner_system.gd")

# Exercise real scene logic without making requests to the production database.
class OfflineResult extends "res://result.gd":
	func _check_cloud_best_score() -> void:
		_finish_upload("离线验证")

class OfflineLogin extends "res://login.gd":
	func _try_restore_session() -> void:
		pass

var checks := 0
var failures := 0
var paths: Array[String] = []
var suffix := str(OS.get_process_id()) + "_" + str(Time.get_ticks_usec())

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func account(name: String) -> void:
	set_meta("supabase_session", {"user": {"id": "reward_test_" + name + suffix}})
	set_meta("song_scores", {})
	paths.append(Partners.profile_path(self))

func result_scene(score: int):
	set_meta("result_data", {"song_id": "leisure", "score": score, "perfect": 44, "max_combo": 44})
	var scene = load("res://result.tscn").instantiate()
	scene.set_script(OfflineResult)
	root.add_child(scene)
	current_scene = scene
	return scene

func run() -> void:
	var full := {"leisure": {"best_score": 1000000}}
	check(Partners.grant_score_rewards(self, full).is_empty(), "guest cannot earn rewards")
	account("a")
	Partners.grant_starter(self)
	check(not Partners.is_owned(self, "qiche"), "login alone does not unlock Qiche")
	check(Partners.get_character("qiche")["unlock"]["score"] == 1000000, "reward requires actual perfect score")
	check(Partners.portrait_texture(Partners.get_character("qiche")) != null, "new portrait imports")
	check(Partners.background_texture(Partners.get_character("qiche")).resource_path.ends_with("home_qiche_dusk.png"), "new background imports")
	var page = load("res://characters.tscn").instantiate()
	root.add_child(page)
	page._select("qiche")
	check(page.action_button.disabled and page.ownership_label.text.contains("1,000,000"), "locked detail shows full-score requirement")
	check(page.portrait.texture != null and page.name_label.text == "祁澈", "locked role can be previewed")
	check(not Partners.select_character(self, "qiche"), "locked role cannot be equipped")
	page.queue_free()
	await process_frame
	check(Partners.grant_score_rewards(self, {"leisure": {"best_score": 999999, "grade": "SSS+"}}).is_empty(), "one point short and SSS+ do not unlock")
	check(Partners.grant_score_rewards(self, {"grandeur": {"best_score": 1000000}}).is_empty(), "another song's full score does not unlock")
	check(Partners.grant_score_rewards(self, {"leisure": null}).is_empty(), "invalid or missing score ignored")
	check(Partners.grant_score_rewards(self, full, "/tmp/missing_reward_directory_" + suffix).is_empty(), "failed save does not report reward")
	check(not Partners.is_owned(self, "qiche"), "failed save leaves ownership unchanged")
	var rewards := Partners.grant_score_rewards(self, full)
	check(rewards.size() == 1 and rewards[0]["id"] == "qiche", "Leisure full score grants Qiche")
	check(Partners.active_character(self)["id"] == "wenxu", "grant does not replace equipped partner")
	check(Partners.grant_score_rewards(self, full).is_empty(), "repeat full score does not grant twice")
	Partners.grant_starter(self)
	check(Partners.is_owned(self, "qiche"), "ownership persists after re-login without scores")
	check(get_meta("partner_profile")["owned"].count("qiche") == 1, "saved reward has no duplicates")
	check(Partners.select_character(self, "qiche"), "unlocked role can be equipped")
	Partners.grant_starter(self)
	check(Partners.active_character(self)["id"] == "qiche", "new equipped role persists")
	var home = load("res://main_menu.tscn").instantiate()
	root.add_child(home)
	check(home.partner_portrait.texture.resource_path.ends_with("qiche.png"), "home displays equipped new portrait")
	check(home.character_background.texture.resource_path.ends_with("home_qiche_dusk.png"), "home displays associated new background")
	home.queue_free()
	await process_frame

	account("b")
	check(Partners.grant_score_rewards(self, full).is_empty(), "account switch cannot reward an unloaded profile")
	check(not Partners.is_owned(self, "qiche"), "account switch cannot inherit ownership")
	Partners.grant_starter(self)
	var result = result_scene(999999)
	check(not Partners.is_owned(self, "qiche") and result.reward_label == null, "near-full result stays locked with no reward notice")
	result.queue_free()
	await process_frame
	result = result_scene(1000000)
	check(Partners.is_owned(self, "qiche"), "real full-score result grants reward offline")
	check(result.reward_label != null and result.reward_label.text.contains("祁澈"), "result announces newly earned character")
	check(Partners.active_character(self)["id"] == "wenxu", "result keeps existing equipped partner")
	result.queue_free()
	await process_frame
	result = result_scene(1000000)
	check(result.reward_label == null, "repeated result has no duplicate notification")
	result.queue_free()
	await process_frame

	account("c")
	var login = load("res://login.tscn").instantiate()
	login.set_script(OfflineLogin)
	root.add_child(login)
	current_scene = login
	login._finish_cloud_scores_load(HTTPRequest.RESULT_SUCCESS, 200, [{"song_id": "leisure", "best_score": 1000000}])
	await process_frame
	await process_frame
	check(current_scene.scene_file_path == "res://main_menu.tscn", "historical score flow enters main menu")
	check(Partners.is_owned(self, "qiche"), "login backfills reward from historical cloud full score")
	check(Partners.active_character(self)["id"] == "wenxu", "historical reward also preserves default selection")
	current_scene.queue_free()
	await process_frame

	for path in paths:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	await create_timer(0.1).timeout
	print("Score reward tests: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)
