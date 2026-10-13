extends SceneTree

const Partners = preload("res://partner_system.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	var catalog := Partners.load_catalog()
	check(not catalog.is_empty(), "character catalog loads")
	check(Partners.get_character("wenxu").get("name") == "闻序", "starter defined by catalog")
	var temporary_catalog := OS.get_user_data_dir().path_join("rg_catalog_test_" + str(OS.get_process_id()) + ".json")
	var catalog_file := FileAccess.open(temporary_catalog, FileAccess.WRITE)
	catalog_file.store_string(JSON.stringify([{"id": " sample "}, {"id": "sample"}, {"id": ""}, 42]))
	catalog_file.close()
	var valid_catalog := Partners.load_catalog(temporary_catalog)
	check(valid_catalog.size() == 1 and valid_catalog[0]["id"] == "sample", "catalog ignores duplicate/empty IDs and normalizes whitespace")
	DirAccess.remove_absolute(temporary_catalog)

	var suffix := str(OS.get_process_id()) + "_" + str(Time.get_ticks_usec())
	set_meta("supabase_session", {"user": {"id": "rg_character_test_a_" + suffix}})
	var first_path := Partners.profile_path(self)
	check(not FileAccess.file_exists(first_path), "test does not overwrite an existing profile")
	if FileAccess.file_exists(first_path):
		quit(1)
		return
	# An old-format save has no version or account metadata and may reference removed characters.
	var legacy_file := FileAccess.open(first_path, FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify({"owned": ["wenxu", "future_unknown", "wenxu"], "active": "removed", "cosmetics": {"badge": "legacy"}}))
	legacy_file.close()
	var profile := Partners.grant_starter(self)
	check(profile["owned"].count("wenxu") == 1, "old ownership survives without duplicate starter")
	check(profile["owned"].has("future_unknown"), "unknown saved ownership retained")
	check(profile["cosmetics"]["badge"] == "legacy", "unrelated saved fields retained")
	check(profile["active"] == "wenxu", "invalid saved selection falls back to owned starter")
	check(Partners.is_owned(self, "wenxu"), "logged-in ownership recognized")
	check(not Partners.select_character(self, "does_not_exist"), "invalid character cannot be equipped")
	check(not Partners.unlock_character(self, "does_not_exist"), "invalid character cannot be unlocked")
	check(Partners.select_character(self, "wenxu"), "owned character selection saves")
	remove_meta("partner_profile")
	profile = Partners.grant_starter(self)
	check(profile["active"] == "wenxu", "selection restored after re-login")

	set_meta("supabase_session", {"user": {"id": "rg_character_test_b_" + suffix}})
	check(not Partners.is_owned(self, "wenxu"), "switching accounts cannot reuse previous in-memory ownership")
	check(not Partners.select_character(self, "wenxu"), "selection blocked before loading new account")
	var second_path := Partners.profile_path(self)
	check(second_path != first_path and not FileAccess.file_exists(second_path), "second account has separate new save")
	profile = Partners.grant_starter(self)
	check(profile["owned"].has("wenxu"), "second login receives starter")

	var extra := Partners.get_character("fixture_partner")
	if not extra.is_empty():
		check(not Partners.is_owned(self, "fixture_partner"), "manual character not granted by login")
		check(not Partners.select_character(self, "fixture_partner"), "locked character cannot be equipped")
		check(Partners.unlock_character(self, "fixture_partner"), "reward API unlocks configured future character")
		check(Partners.unlock_character(self, "fixture_partner"), "repeat unlock is idempotent")
		check(get_meta("partner_profile")["owned"].count("fixture_partner") == 1, "no duplicate reward entry")
		check(Partners.select_character(self, "fixture_partner"), "second character can be selected")
		profile = Partners.grant_starter(self)
		check(profile["active"] == "fixture_partner", "login does not reset chosen character")
		check(Partners.active_character(self)["portrait"] == extra["portrait"], "active portrait is configured rather than hardcoded")
	print("Future-character fixture exercised: ", not extra.is_empty())

	var home = load("res://main_menu.tscn").instantiate()
	root.add_child(home)
	current_scene = home
	await process_frame
	var active := Partners.active_character(self)
	check(home.partner_portrait.texture.resource_path == str(active["portrait"]), "home displays selected character asset")
	check(home.partner_button.tooltip_text.begins_with(str(active["name"])), "home click target identifies active partner")
	check(home.partner_button.get_rect().position.x > home.start_button.get_rect().end.x, "character click target does not cover Enter")
	home.partner_button.pressed.emit()
	await process_frame
	await process_frame
	check(current_scene != null and current_scene.scene_file_path == "res://characters.tscn", "clicking partner opens character collection")
	var page = current_scene
	check(page.character_buttons.size() == catalog.size(), "one list item for every configured character")
	check(page.name_label.text == str(active["name"]), "detail opens on selected partner")
	check(page.portrait.texture != null, "detail portrait loads")
	check(page.action_button.disabled, "current partner already equipped")
	page._select("wenxu")
	check(page.name_label.text == "闻序", "detail selection updates name")
	if not extra.is_empty():
		check(not page.action_button.disabled, "another owned partner can be equipped")
		page.action_button.pressed.emit()
		check(get_meta("partner_profile")["active"] == "wenxu", "UI button changes active character")
		check(page.action_button.disabled, "UI updates after successful selection")
	page._back()
	await process_frame
	await process_frame
	check(current_scene != null and current_scene.scene_file_path == "res://main_menu.tscn", "return to home works")
	check(current_scene.partner_button.tooltip_text.begins_with("闻序"), "home reflects selected character after return")
	current_scene.characters_button.pressed.emit()
	await process_frame
	await process_frame
	check(current_scene.scene_file_path == "res://characters.tscn", "visible Characters button opens collection")
	current_scene._back()
	await process_frame
	await process_frame
	var key := InputEventKey.new()
	key.keycode = KEY_C
	key.pressed = true
	current_scene._unhandled_input(key)
	await process_frame
	await process_frame
	check(current_scene.scene_file_path == "res://characters.tscn", "C shortcut opens collection")
	current_scene.queue_free()
	await process_frame
	remove_meta("supabase_session")
	Partners.grant_starter(self)
	check(not Partners.is_owned(self, "wenxu"), "guest does not retain ownership")
	check(not Partners.select_character(self, "wenxu"), "guest cannot equip")
	check(not Partners.unlock_character(self, "wenxu"), "guest cannot unlock")
	var guest_page = load("res://characters.tscn").instantiate()
	root.add_child(guest_page)
	await process_frame
	check(guest_page.action_button.disabled and guest_page.status_label.text.contains("登录"), "guest preview gives login requirement")
	guest_page.queue_free()
	await process_frame
	for path in [first_path, second_path]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	await create_timer(0.1).timeout
	print("Character tests: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)
