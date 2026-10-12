extends Control

func _ready() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("#10131D")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var title := Label.new()
	title.text = "RHYTHM GAY"
	title.position = Vector2(0, 250)
	title.size = Vector2(720, 90)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	add_child(title)

	var start := Button.new()
	start.text = "开始游戏（Enter）"
	start.position = Vector2(210, 540)
	start.size = Vector2(300, 70)
	start.add_theme_font_size_override("font_size", 26)
	start.pressed.connect(_start_game)
	add_child(start)
	start.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_start_game()

func _start_game() -> void:
	get_tree().change_scene_to_file("res://song_select.tscn")
