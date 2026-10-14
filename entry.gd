extends Control

const UI = preload("res://ui/rhythm_ui.gd")
const Brand = preload("res://ui/brand.gd")
const SESSION_FILE := "user://supabase_session.json"

var login_button: Button
var status_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UI.setup(self, true)

	var default_background := get_child(0)
	if default_background is Control:
		default_background.hide()

	var background := TextureRect.new()
	background.texture = preload("res://assets/backgrounds/entry_atrium.png")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -10
	add_child(background)
	move_child(background, 0)

	UI.label(self, "THETALE  /  RHYTHM GAME", Rect2(56, 66, 608, 40), 17, UI.CYAN)
	Brand.title(self, "Thetale", Rect2(56, 170, 608, 90), 68)
	Brand.accent_line(self, Rect2(294, 264, 132, 3))
	UI.label(self, "每一次敲击，都与节奏共鸣。", Rect2(56, 300, 608, 40), 21, UI.MUTED)

	login_button = Button.new()
	login_button.text = "登录"
	login_button.position = Vector2(88, 990)
	login_button.size = Vector2(544, 72)
	login_button.z_index = 10
	login_button.add_theme_font_size_override("font_size", 24)
	UI.primary(login_button)
	login_button.pressed.connect(_open_login)
	add_child(login_button)
	login_button.grab_focus()

	status_label = Label.new()
	status_label.position = Vector2(88, 885)
	status_label.size = Vector2(544, 48)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", UI.MUTED)
	status_label.add_theme_font_size_override("font_size", 17)
	add_child(status_label)

func _open_login() -> void:
	login_button.disabled = true
	if not FileAccess.file_exists(SESSION_FILE):
		status_label.text = "正在打开登录界面……"
		get_tree().set_meta("silent_restore_login", false)
		get_tree().change_scene_to_file("res://login.tscn")
		return

	status_label.text = "正在恢复登录……"
	get_tree().set_meta("silent_restore_login", true)
	var login_scene := preload("res://login.tscn").instantiate()
	add_child(login_scene)
	login_scene.visible = false
