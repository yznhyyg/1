extends Control

const RatingSystem = preload("res://rating_system.gd")
const PartnerSystem = preload("res://partner_system.gd")
const UI = preload("res://ui/rhythm_ui.gd")

var personal_rating_label: Label
var partner_portrait: TextureRect
var start_button: Button

func _ready() -> void:
	UI.setup(self, true)
	# The portrait is also visible when previewing this scene in the editor.
	# Actual ownership is granted only by the successful login flow.
	partner_portrait = TextureRect.new()
	partner_portrait.name = "PartnerPortrait"
	partner_portrait.texture = load(PartnerSystem.STARTER_PORTRAIT)
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

	var tip := UI.label(self, "TIP / 让每一个音符，都成为你的高光。", Rect2(44, 1168, 592, 56), 16, UI.MUTED)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.reveal(self)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_start_game()

func _start_game() -> void:
	get_tree().change_scene_to_file("res://song_select.tscn")
