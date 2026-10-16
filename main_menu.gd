extends Control

const RatingSystem = preload("res://rating_system.gd")
const PartnerSystem = preload("res://partner_system.gd")
const UI = preload("res://ui/rhythm_ui.gd")
const Brand = preload("res://ui/brand.gd")
const RatingDigits = preload("res://ui/rating_digits.gd")
const RatingPattern = preload("res://ui/rating_pattern.gd")
const Atmosphere = preload("res://ui/atmosphere.gd")
const PortraitMotion = preload("res://ui/portrait_motion.gd")
const PortraitFrames = preload("res://ui/portrait_frames.gd")

var personal_rating_label: Label
var partner_portrait: TextureRect
var character_background: TextureRect
var start_button: Button
var partner_button: Button
var characters_button: Button
var portrait_frames: PortraitFrames

# Rating frame candidates: 1 = violet capsule, 2 = cyan glass, 3 = sharp neon.
# Keep this value at 2 for the current default; it can be changed after previewing.
const RATING_FRAME_OPTION := 2

func _ready() -> void:
	UI.setup(self, true)
	var character := PartnerSystem.active_character(get_tree())
	character_background = TextureRect.new()
	character_background.name = "HomeBackground"
	character_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	character_background.texture = PartnerSystem.background_texture(character)
	character_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	character_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	character_background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	character_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(character_background)
	if character_background.texture != null:
		# The opaque picture replaces the procedural backdrop; avoid drawing both.
		get_child(0).hide()
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.035, 0.059, 0.114, 0.30)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var atmosphere := Atmosphere.new()
	atmosphere.name = "AnimatedAtmosphere"
	atmosphere.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(atmosphere)
	# The portrait is also visible when previewing this scene in the editor.
	# Actual ownership is granted only by the successful login flow.
	partner_portrait = TextureRect.new()
	partner_portrait.name = "PartnerPortrait"
	partner_portrait.texture = PartnerSystem.portrait_texture(character)
	partner_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	partner_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	partner_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	partner_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	partner_portrait.anchor_left = 1.0
	partner_portrait.anchor_right = 1.0
	partner_portrait.offset_left = -580
	partner_portrait.offset_right = 40
	partner_portrait.offset_top = 164
	partner_portrait.offset_bottom = 1094
	add_child(partner_portrait)
	var portrait_motion := PortraitMotion.new()
	portrait_motion.setup(partner_portrait, 0.35)
	add_child(portrait_motion)
	portrait_frames = PortraitFrames.new()
	portrait_frames.setup(partner_portrait)
	portrait_frames.set_character(str(character.get("id", "")))
	add_child(portrait_frames)
	if partner_portrait.texture == null:
		UI.label(self, "立绘待补充", Rect2(330, 580, 320, 48), 20, UI.MUTED)
	# A transparent hit area stays to the right of the home controls.
	partner_button = Button.new()
	partner_button.name = "OpenCharacters"
	partner_button.anchor_left = 1.0
	partner_button.anchor_right = 1.0
	partner_button.offset_left = -438
	partner_button.offset_right = -20
	partner_button.offset_top = 164
	partner_button.offset_bottom = 1094
	partner_button.focus_mode = Control.FOCUS_NONE
	partner_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	partner_button.tooltip_text = str(character.get("name", "角色")) + " · 查看角色（C）"
	for state in ["normal", "hover", "pressed", "focus"]:
		partner_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	partner_button.pressed.connect(_open_characters)
	add_child(partner_button)

	var logo_texture := load("res://assets/branding/thetale_logo_a.png") as Texture2D
	if logo_texture != null:
		var logo := Sprite2D.new()
		logo.texture = logo_texture
		logo.position = Vector2(190, 259)
		logo.scale = Vector2.ONE * (350.0 / float(logo_texture.get_width()))
		logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(logo)
	else:
		Brand.title(self, "Thetale", Rect2(35, 218, 350, 96), 66)
		Brand.accent_line(self, Rect2(105, 324, 190, 3))
	var songs := RatingSystem.load_catalog()
	get_tree().set_meta("song_catalog", songs)
	var scores = get_tree().get_meta("song_scores", {})
	if not scores is Dictionary:
		scores = {}
	var rating_card := Panel.new()
	rating_card.position = Vector2(40, 460)
	rating_card.size = Vector2(260, 130)
	rating_card.clip_contents = true
	rating_card.add_theme_stylebox_override("panel", _rating_frame(RATING_FRAME_OPTION))
	add_child(rating_card)
	var rating_pattern := RatingPattern.new()
	rating_pattern.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rating_pattern.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rating_card.add_child(rating_pattern)
	var rating_texture := load("res://assets/branding/thetale_rating_b.png") as Texture2D
	if rating_texture != null:
		var rating_logo := Sprite2D.new()
		rating_logo.texture = rating_texture
		rating_logo.position = Vector2(130, 28)
		rating_logo.scale = Vector2.ONE * (220.0 / float(rating_texture.get_width()))
		rating_logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		rating_card.add_child(rating_logo)
	else:
		var rating_heading := UI.label(rating_card, "RATING", Rect2(20, 10, 204, 28), 17, UI.CYAN)
		rating_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	personal_rating_label = RatingDigits.new()
	personal_rating_label.position = Vector2(64, 510)
	personal_rating_label.size = Vector2(212, 70)
	personal_rating_label.text = "%.3f" % RatingSystem.personal_rating(songs, scores)
	personal_rating_label.add_theme_font_size_override("font_size", 40)
	add_child(personal_rating_label)
	personal_rating_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	personal_rating_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	start_button = Button.new()
	start_button.text = ""
	start_button.position = Vector2(44, 618)
	start_button.size = Vector2(224, 64)
	start_button.add_theme_stylebox_override("normal", UI.box(Color("#14203A"), Color("#B6A6FF"), 32))
	start_button.add_theme_stylebox_override("hover", UI.box(Color("#243153"), Color("#D0C6FF"), 32))
	start_button.add_theme_stylebox_override("pressed", UI.box(Color("#0D162B"), Color("#9C87FF"), 32))
	start_button.add_theme_stylebox_override("focus", UI.box(Color("#14203A"), Color("#66E7DA"), 32))
	start_button.add_theme_color_override("font_color", Color("#F4F1FF"))
	start_button.add_theme_color_override("font_hover_color", Color.WHITE)
	start_button.add_theme_font_size_override("font_size", 22)
	var enter_texture := load("res://assets/branding/thetale_enter_a.png") as Texture2D
	if enter_texture != null:
		var enter_logo := Sprite2D.new()
		enter_logo.texture = enter_texture
		enter_logo.position = Vector2(start_button.size.x * 0.5 + 3.0, start_button.size.y * 0.5)
		enter_logo.scale = Vector2.ONE * (142.0 / float(enter_texture.get_width()))
		enter_logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		start_button.add_child(enter_logo)
	else:
		start_button.text = "ENTER  →"
	start_button.pressed.connect(_start_game)
	add_child(start_button)
	start_button.grab_focus()
	characters_button = Button.new()
	characters_button.name = "CharactersButton"
	characters_button.text = "角色"
	characters_button.position = Vector2(470, 1080)
	characters_button.size = Vector2(210, 54)
	characters_button.add_theme_font_size_override("font_size", 18)
	characters_button.pressed.connect(_open_characters)
	add_child(characters_button)

	var tip := UI.label(self, "TIP / 点击伙伴或按 C，查看角色。", Rect2(44, 1168, 592, 56), 16, UI.MUTED)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.reveal(self)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_start_game()
	elif event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_C or event.physical_keycode == KEY_C):
		_open_characters()

func _open_characters() -> void:
	get_tree().change_scene_to_file("res://characters.tscn")

func _start_game() -> void:
	get_tree().change_scene_to_file("res://song_select.tscn")

func _rating_frame(option: int) -> StyleBoxFlat:
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("#101A30")
	frame.corner_radius_top_left = 22
	frame.corner_radius_top_right = 22
	frame.corner_radius_bottom_right = 22
	frame.corner_radius_bottom_left = 22
	frame.content_margin_left = 12.0
	frame.content_margin_right = 12.0
	frame.content_margin_top = 8.0
	frame.content_margin_bottom = 8.0
	match option:
		1:
			frame.border_color = Color("#7767D7")
			frame.set_border_width_all(2)
		2:
			frame.bg_color = Color(0.055, 0.11, 0.19, 0.88)
			frame.border_color = Color("#66E7DA")
			frame.set_border_width_all(2)
			frame.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
			frame.shadow_size = 8
		3:
			frame.bg_color = Color("#0B1224")
			frame.border_color = Color("#B6A6FF")
			frame.set_border_width_all(2)
			frame.corner_radius_top_left = 8
			frame.corner_radius_top_right = 28
			frame.corner_radius_bottom_right = 8
			frame.corner_radius_bottom_left = 28
	return frame
