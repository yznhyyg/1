extends RefCounted

const CATALOG_PATH := "res://characters/catalog.json"
const STARTER_ID := "wenxu"
const STARTER_NAME := "闻序"
const STARTER_PORTRAIT := "res://assets/characters/wenxu.png"
const DEFAULT_BACKGROUND := "res://assets/backgrounds/home_midnight_atrium.png"

static func load_catalog(path: String = CATALOG_PATH) -> Array[Dictionary]:
	var characters: Array[Dictionary] = []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("无法读取角色配置：" + path)
		return characters
	var saved = JSON.parse_string(file.get_as_text())
	if not saved is Array:
		push_warning("角色配置必须是数组：" + path)
		return characters
	var seen: Dictionary = {}
	for item in saved:
		if not item is Dictionary:
			continue
		var id := str(item.get("id", "")).strip_edges()
		if id.is_empty() or seen.has(id):
			continue
		seen[id] = true
		item["id"] = id
		characters.append(item)
	return characters

static func get_character(id: String) -> Dictionary:
	for character in load_catalog():
		if str(character.get("id", "")) == id:
			return character
	return {}

static func _texture_from_path(path: String) -> Texture2D:
	if not path.begins_with("res://") or not ResourceLoader.exists(path):
		return null
	var resource = load(path)
	return resource if resource is Texture2D else null

static func portrait_texture(character: Dictionary) -> Texture2D:
	return _texture_from_path(str(character.get("portrait", "")))

static func background_texture(character: Dictionary) -> Texture2D:
	var texture := _texture_from_path(str(character.get("background", "")))
	return texture if texture != null else _texture_from_path(DEFAULT_BACKGROUND)

static func user_id(tree: SceneTree) -> String:
	var session = tree.get_meta("supabase_session", {})
	var user = session.get("user", {}) if session is Dictionary else {}
	return str(user.get("id", "")) if user is Dictionary else ""

static func profile_path(tree: SceneTree, storage_directory: String = "user://") -> String:
	var id := user_id(tree)
	return "" if id.is_empty() else storage_directory.path_join("partners_" + id.sha256_text() + ".json")

static func _profile(tree: SceneTree) -> Dictionary:
	var id := user_id(tree)
	if id.is_empty() or str(tree.get_meta("partner_profile_user", "")) != id:
		return {}
	var profile = tree.get_meta("partner_profile", {})
	return profile if profile is Dictionary else {}

static func is_owned(tree: SceneTree, id: String) -> bool:
	var owned = _profile(tree).get("owned", [])
	return owned is Array and owned.has(id)

static func active_character(tree: SceneTree) -> Dictionary:
	var id := str(_profile(tree).get("active", ""))
	if is_owned(tree, id):
		var character := get_character(id)
		if not character.is_empty():
			return character
	# Editor/guest previews can show the starter without granting ownership.
	return get_character(STARTER_ID)

static func _store(tree: SceneTree, profile: Dictionary, storage_directory: String) -> bool:
	var path := profile_path(tree, storage_directory)
	if path.is_empty():
		return false
	# Write separately before replacing the current file so incomplete writes cannot erase it.
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(profile))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
		return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)) == OK

static func grant_starter(tree: SceneTree, storage_directory: String = "user://") -> Dictionary:
	var id := user_id(tree)
	if id.is_empty():
		for key in ["partner_profile", "partner_profile_user"]:
			if tree.has_meta(key):
				tree.remove_meta(key)
		return {}
	var path := profile_path(tree, storage_directory)
	var profile: Dictionary = {}
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			var saved = JSON.parse_string(file.get_as_text())
			if saved is Dictionary:
				profile = saved
	var previous = profile.get("owned", [])
	var owned: Array[String] = []
	if previous is Array:
		for item in previous:
			if item is String and not item.is_empty() and not owned.has(item):
				owned.append(item)
	var catalog := load_catalog()
	for character in catalog:
		var unlock = character.get("unlock", {})
		if unlock is Dictionary and str(unlock.get("type", "manual")) == "login":
			var character_id := str(character["id"])
			if not owned.has(character_id):
				owned.append(character_id)
	profile["owned"] = owned
	var active := str(profile.get("active", ""))
	if not owned.has(active) or get_character(active).is_empty():
		profile["active"] = ""
		for character in catalog:
			if owned.has(str(character["id"])):
				profile["active"] = str(character["id"])
				break
	if not _store(tree, profile, storage_directory):
		push_warning("角色数据暂时无法保存，登录赠送的角色仍在本次登录中可用。")
	tree.set_meta("partner_profile", profile)
	tree.set_meta("partner_profile_user", id)
	return profile

static func unlock_character(tree: SceneTree, id: String, storage_directory: String = "user://") -> bool:
	if _profile(tree).is_empty() or get_character(id).is_empty():
		return false
	if is_owned(tree, id):
		return true
	var profile := _profile(tree).duplicate(true)
	profile["owned"].append(id)
	if not _store(tree, profile, storage_directory):
		return false
	tree.set_meta("partner_profile", profile)
	return true

static func grant_score_rewards(tree: SceneTree, scores: Dictionary, storage_directory: String = "user://") -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	if _profile(tree).is_empty():
		return rewards
	var profile := _profile(tree).duplicate(true)
	for character in load_catalog():
		var id := str(character["id"])
		if profile["owned"].has(id):
			continue
		var unlock = character.get("unlock", {})
		if not unlock is Dictionary or str(unlock.get("type", "")) != "song_score":
			continue
		var song_id := str(unlock.get("song_id", ""))
		var required_score := int(unlock.get("score", 0))
		var record = scores.get(song_id, {})
		if song_id.is_empty() or required_score <= 0 or not record is Dictionary:
			continue
		if int(record.get("best_score", 0)) < required_score:
			continue
		profile["owned"].append(id)
		rewards.append(character)
	# Preserve the equipped character; only announce rewards after they are saved.
	if not rewards.is_empty():
		if not _store(tree, profile, storage_directory):
			push_warning("角色奖励暂时无法保存，下次读取成绩时会再次尝试。")
			rewards.clear()
		else:
			tree.set_meta("partner_profile", profile)
	return rewards

static func grant_login_day_rewards(tree: SceneTree, login_days: int, storage_directory: String = "user://") -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	if _profile(tree).is_empty():
		return rewards
	var profile := _profile(tree).duplicate(true)
	var owned = profile.get("owned", [])
	if not owned is Array:
		return rewards
	for character in load_catalog():
		var id := str(character.get("id", ""))
		if id.is_empty() or owned.has(id):
			continue
		var unlock = character.get("unlock", {})
		if not unlock is Dictionary or str(unlock.get("type", "")) != "login_days":
			continue
		var required_days := int(unlock.get("days", 0))
		if required_days <= 0 or login_days < required_days:
			continue
		owned.append(id)
		rewards.append(character)
	if not rewards.is_empty():
		profile["owned"] = owned
		if not _store(tree, profile, storage_directory):
			push_warning("登录天数角色奖励暂时无法保存，下次登录时会再次尝试。")
			rewards.clear()
		else:
			tree.set_meta("partner_profile", profile)
	return rewards

static func select_character(tree: SceneTree, id: String, storage_directory: String = "user://") -> bool:
	if not is_owned(tree, id) or get_character(id).is_empty():
		return false
	var profile := _profile(tree).duplicate(true)
	profile["active"] = id
	if not _store(tree, profile, storage_directory):
		return false
	tree.set_meta("partner_profile", profile)
	return true
