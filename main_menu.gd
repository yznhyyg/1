extends Control

const RatingSystem = preload("res://rating_system.gd")
const PartnerSystem = preload("res://partner_system.gd")
const UI = preload("res://ui/rhythm_ui.gd")

var personal_rating_label: Label
var partner_portrait: TextureRect
var character_background: TextureRect
var start_button: Button
var partner_button: Button
var characters_button: Button

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
	shade.color = Color(0.035, 0.059, 0.114, 0.22)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	# The portrait is also visible when previewing this scene in the editor.
	# Actual ownership is granted only by the successful login flow.
	partner_portrait = TextureRect.new()
	partner_portrait.name = "PartnerPortrait"
	partner_portrait.texture = PartnerSystem.portrait_texture(character)
	partner_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	partner_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	partner_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	partner_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	partner_portrait.anchor_left = 1.0
	partner_portrait.anchor_right = 1.0
	partner_portrait.offset_left = -580
	partner_portrait.offset_right = 40
	partner_portrait.offset_top = 164
	partner_portrait.offset_bottom = 1094
	add_child(partner_portrait)
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

	UI.label(self, "RHYTHM\nGAME", Rect2(44, 218, 244, 156), 44)
	var songs := RatingSystem.load_catalog()
	get_tree().set_meta("song_catalog", songs)
	var scores = get_tree().get_meta("song_scores", {})
	if not scores is Dictionary:
		scores = {}
	UI.card(self, Rect2(44, 460, 224, 110))
	var rating_heading := UI.label(self, "RATING", Rect2(60, 476, 192, 25), 17, UI.CYAN)
	rating_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	personal_rating_label = UI.label(self, "%.3f" % RatingSystem.personal_rating(songs, scores), Rect2(60, 508, 192, 54), 38, Color("#FF75BC"))
	personal_rating_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	personal_rating_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	start_button = Button.new()
	start_button.text = "ENTER  →"
	start_button.position = Vector2(44, 618)
	start_button.size = Vector2(224, 64)
	UI.primary(start_button)
	start_button.add_theme_font_size_override("font_size", 22)
	start_button.pressed.connect(_start_game)
	add_child(start_button)
	start_button.grab_focus()
	characters_button = Button.new()
	characters_button.name = "CharactersButton"
	characters_button.text = "角色"
	characters_button.position = Vector2(44, 704)
	characters_button.size = Vector2(224, 48)
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
