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
	var directory := "/tmp/rg-partner-test-" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(directory)
	check(Partners.grant_starter(self, directory).is_empty(), "no partner grant without login")
	check(DirAccess.open(directory).get_files().is_empty(), "guest does not create a profile")
	set_meta("supabase_session", {"user": {"id": "test-player-a"}})
	var profile := Partners.grant_starter(self, directory)
	check(profile["owned"] == ["wenxu"], "first login unlocks starter")
	check(profile["active"] == "wenxu", "starter is selected by default")
	check(get_meta("partner_profile")["owned"].has("wenxu"), "partner ownership available to game")
	check(Partners.STARTER_NAME == "闻序", "starter name")
	profile = Partners.grant_starter(self, directory)
	check(profile["owned"].size() == 1, "repeated login does not duplicate grant")
	# Restore from disk after clearing session metadata, as on a fresh application run.
	remove_meta("partner_profile")
	profile = Partners.grant_starter(self, directory)
	check(profile["owned"].has("wenxu"), "ownership restored after restart")
	set_meta("supabase_session", {"user": {"id": "test-player-b"}})
	profile = Partners.grant_starter(self, directory)
	check(profile["owned"] == ["wenxu"], "second account receives its own starter")
	check(DirAccess.open(directory).get_files().size() == 2, "account profiles stored separately")
	remove_meta("supabase_session")
	Partners.grant_starter(self, directory)
	check(not has_meta("partner_profile"), "guest does not inherit previous account profile")

	var home = load("res://main_menu.tscn").instantiate()
	root.add_child(home)
	current_scene = home
	await process_frame
	check(home.partner_portrait.texture != null, "home character texture loads")
	check(home.partner_portrait.mouse_filter == Control.MOUSE_FILTER_IGNORE, "character does not block buttons")
	check(not has_meta("partner_profile"), "editor preview does not grant ownership")
	check(home.start_button.size.x <= 224, "compact enter button")
	check(home.personal_rating_label.text == "0.000", "rating keeps three decimals")
	var image: Image = home.partner_portrait.texture.get_image()
	check(image.get_format() == Image.FORMAT_RGBA8, "character has alpha channel")
	check(image.get_pixel(0, 0).a == 0.0, "character background is transparent")
	home.start_button.pressed.emit()
	await process_frame
	await process_frame
	check(current_scene != null and current_scene.scene_file_path == "res://song_select.tscn", "enter button opens song selection")
	if current_scene != null:
		current_scene.preview_player.stop()
		if current_scene.preview_tween != null:
			current_scene.preview_tween.kill()
		current_scene.queue_free()
	await process_frame
	for filename in DirAccess.open(directory).get_files():
		DirAccess.remove_absolute(directory.path_join(filename))
	DirAccess.remove_absolute(directory)
	# Give the audio thread time to release stopped preview streams before exit.
	await create_timer(0.1).timeout
	print("Partner tests: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)
