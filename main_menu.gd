extends Control

const UI = preload("res://ui/rhythm_ui.gd")

func _ready() -> void:
	UI.setup(self)

	UI.label(self, "RG  /  RHYTHM GAME", Rect2(56, 66, 608, 40), 17, UI.CYAN)
	UI.label(self, "FIND YOUR RHYTHM", Rect2(56, 185, 608, 35), 18, UI.ACCENT)
	UI.label(self, "跟随节奏，突破极限。", Rect2(56, 425, 608, 45), 26, UI.MUTED)
	UI.card(self, Rect2(56, 510, 608, 260))
	UI.label(self, "准备好下一场演奏了吗？", Rect2(88, 544, 544, 44), 25)
	UI.label(self, "D  /  F  /  J  /  K     ·     四轨节奏", Rect2(88, 602, 544, 35), 19, UI.MUTED)
	UI.label(self, "让每一个音符，都成为你的高光。", Rect2(56, 1090, 608, 40), 19, UI.MUTED)
	UI.reveal(self)
	var title := Label.new()
	title.text = "RHYTHM\nGAME"
	title.position = Vector2(52, 230)
	title.size = Vector2(616, 190)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_size_override("font_size", 64)
	add_child(title)

	var start := Button.new()
	start.text = "开始游戏（Enter）"
	start.position = Vector2(88, 672)
	start.size = Vector2(544, 70)
	start.add_theme_font_size_override("font_size", 26)
	UI.primary(start)
	start.pressed.connect(_start_game)
	add_child(start)
	start.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_start_game()

func _start_game() -> void:
	get_tree().change_scene_to_file("res://song_select.tscn")
