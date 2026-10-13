extends RefCounted

const STARTER_ID := "wenxu"
const STARTER_NAME := "闻序"
const STARTER_PORTRAIT := "res://assets/characters/wenxu.png"

static func grant_starter(tree: SceneTree, storage_directory: String = "user://") -> Dictionary:
	var session = tree.get_meta("supabase_session", {})
	var user = session.get("user", {}) if session is Dictionary else {}
	var user_id := str(user.get("id", "")) if user is Dictionary else ""
	if user_id.is_empty():
		if tree.has_meta("partner_profile"):
			tree.remove_meta("partner_profile")
		return {}
	# Only a hash of the account ID is used in the filename; no credentials are stored.
	var path := storage_directory.path_join("partners_" + user_id.sha256_text() + ".json")
	var profile: Dictionary = {}
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			var saved = JSON.parse_string(file.get_as_text())
			if saved is Dictionary:
				profile = saved
	var owned = profile.get("owned", [])
	if not owned is Array:
		owned = []
	if not owned.has(STARTER_ID):
		owned.append(STARTER_ID)
	profile["owned"] = owned
	# The initial partner is available on every device after login.
	if str(profile.get("active", "")).is_empty() or not owned.has(profile.get("active")):
		profile["active"] = STARTER_ID
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(profile))
	else:
		push_warning("伙伴数据暂时无法保存，初始伙伴仍在本次登录中可用。")
	tree.set_meta("partner_profile", profile)
	return profile
