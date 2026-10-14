extends Control

const UI = preload("res://ui/rhythm_ui.gd")
const Brand = preload("res://ui/brand.gd")
const SESSION_FILE := "user://supabase_session.json"

var login_button: Button

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

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.025, 0.07, 0.46)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	move_child(shade, 1)

	var logo_texture := load("res://assets/branding/thetale_logo_a.png") as Texture2D
	if logo_texture != null:
		var logo := Sprite2D.new()
		logo.texture = logo_texture
		logo.position = Vector2(360, 270)
		var logo_scale := 616.0 / float(logo_texture.get_width())
		logo.scale = Vector2.ONE * logo_scale
		logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(logo)
	else:
		Brand.title(self, "Thetale", Rect2(52, 170, 616, 100), 68)

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

func _open_login() -> void:
	login_button.disabled = true
	if not FileAccess.file_exists(SESSION_FILE):
		get_tree().set_meta("silent_restore_login", false)
		get_tree().change_scene_to_file("res://login.tscn")
		return

	get_tree().set_meta("silent_restore_login", true)
	var login_scene := preload("res://login.tscn").instantiate()
	add_child(login_scene)
	login_scene.visible = false
