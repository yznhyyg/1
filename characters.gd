extends Control

const UI = preload("res://ui/rhythm_ui.gd")
const Brand = preload("res://ui/brand.gd")
const Partners = preload("res://partner_system.gd")
const Atmosphere = preload("res://ui/atmosphere.gd")

var characters: Array[Dictionary] = []
var selected_id := ""
var character_background: TextureRect
var portrait: TextureRect
var portrait_placeholder: Label
var name_label: Label
var title_label: Label
var quote_label: Label
var description_label: Label
var ownership_label: Label
var count_label: Label
var status_label: Label
var action_button: Button
var list_box: VBoxContainer
var character_buttons: Array[Button] = []
var portrait_base_position := Vector2.ZERO
var portrait_elapsed := 0.0

func _ready() -> void:
	UI.setup(self, true)
	var default_background := get_child(0)
	if default_background is Control:
		default_background.hide()
	var background := TextureRect.new()
	background.texture = preload("res://assets/backgrounds/home_midnight_atrium.png")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	move_child(background, 0)
	character_background = background
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.025, 0.07, 0.42)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	move_child(shade, 1)
	var atmosphere := Atmosphere.new()
	atmosphere.name = "AnimatedAtmosphere"
	atmosphere.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(atmosphere)
	characters = Partners.load_catalog()
	_update_character_background(Partners.active_character(get_tree()))
	var logo_texture := load("res://assets/branding/thetale_logo_a.png") as Texture2D
	if logo_texture != null:
		var logo := Sprite2D.new()
		logo.texture = logo_texture
		logo.position = Vector2(560, 51)
		logo.scale = Vector2.ONE * (270.0 / float(logo_texture.get_width()))
		logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(logo)
	else:
		Brand.title(self, "Thetale", Rect2(390, 18, 300, 70), 42)
	var back := Button.new()
	back.text = "← 返回"
	back.position = Vector2(32, 84)
	back.size = Vector2(124, 48)
	back.add_theme_font_size_override("font_size", 18)
	back.pressed.connect(_back)
	add_child(back)
	UI.label(self, "与你同行", Rect2(44, 157, 620, 58), 38)
	UI.card(self, Rect2(32, 230, 656, 620))
	portrait = TextureRect.new()
	portrait.position = Vector2(286, 246)
	portrait.size = Vector2(400, 592)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(portrait)
	portrait_base_position = portrait.position
	portrait_placeholder = UI.label(self, "立绘待补充", Rect2(400, 478, 240, 40), 20, UI.MUTED)
	name_label = UI.label(self, "", Rect2(56, 274, 256, 60), 38)
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label = UI.label(self, "", Rect2(56, 336, 256, 54), 18, UI.MUTED)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.max_lines_visible = 2
	quote_label = UI.label(self, "", Rect2(56, 409, 256, 120), 22, UI.CYAN)
	quote_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote_label.max_lines_visible = 3
	description_label = UI.label(self, "", Rect2(56, 560, 256, 184), 17, UI.MUTED)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.max_lines_visible = 7
	ownership_label = UI.label(self, "", Rect2(56, 769, 256, 52), 17, UI.CYAN)
	ownership_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ownership_label.max_lines_visible = 2
	UI.label(self, "角色收藏", Rect2(44, 871, 300, 34), 22)
	count_label = UI.label(self, "", Rect2(432, 874, 244, 30), 17, UI.MUTED)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(32, 922)
	scroll.size = Vector2(656, 162)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	list_box = VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation", 10)
	scroll.add_child(list_box)
	for character in characters:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 64)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 19)
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.pressed.connect(_select.bind(str(character["id"])))
		list_box.add_child(button)
		character_buttons.append(button)
	status_label = UI.label(self, "", Rect2(32, 1098, 656, 44), 17, UI.MUTED)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_button = Button.new()
	action_button.position = Vector2(32, 1160)
	action_button.size = Vector2(656, 72)
	UI.primary(action_button)
	action_button.pressed.connect(_choose_partner)
	add_child(action_button)
	var active := Partners.active_character(get_tree())
	if not active.is_empty():
		_select(str(active["id"]))
	elif not characters.is_empty():
		_select(str(characters[0]["id"]))
	else:
		name_label.text = "暂无角色"
		action_button.text = "暂无可选择的伙伴"
		action_button.disabled = true
	if Partners.user_id(get_tree()).is_empty():
		status_label.text = "登录后即可获得初始伙伴"
	back.grab_focus()
	UI.reveal(self)

func _process(delta: float) -> void:
	portrait_elapsed += delta
	if is_instance_valid(portrait):
		portrait.position.y = portrait_base_position.y + sin(portrait_elapsed * 0.78 + 0.6) * 2.5
		var breath := 1.0 + sin(portrait_elapsed * 0.58) * 0.003
		portrait.scale = Vector2(breath, breath)

func _select(id: String) -> void:
	var character := Partners.get_character(id)
	if character.is_empty():
		return
	selected_id = id
	_update_character_background(character)
	name_label.text = str(character.get("name", id))
	name_label.tooltip_text = name_label.text
	title_label.text = str(character.get("title", ""))
	quote_label.text = "“%s”" % str(character.get("quote", "")) if not str(character.get("quote", "")).is_empty() else ""
	description_label.text = str(character.get("description", ""))
	var accent := Color.from_string(str(character.get("accent", "#66E7DA")), UI.CYAN)
	quote_label.add_theme_color_override("font_color", accent)
	portrait.texture = Partners.portrait_texture(character)
	portrait_placeholder.visible = portrait.texture == null
	var owned := Partners.is_owned(get_tree(), id)
	var active := str(get_tree().get_meta("partner_profile", {}).get("active", "")) if owned else ""
	var unlock = character.get("unlock", {})
	var unlock_text := str(unlock.get("description", "等待解锁")) if unlock is Dictionary else "等待解锁"
	ownership_label.text = "已拥有 · 当前上场" if owned and active == id else ("已拥有" if owned else "未拥有 · " + unlock_text)
	ownership_label.add_theme_color_override("font_color", accent if owned else UI.MUTED)
	action_button.disabled = not owned or active == id
	action_button.text = "当前上场角色" if owned and active == id else ("设为上场角色" if owned else "尚未拥有")
	_refresh_list()

func _update_character_background(character: Dictionary) -> void:
	if character_background == null:
		return
	character_background.texture = Partners.background_texture(character)

func _refresh_list() -> void:
	var count := 0
	var active := str(Partners.active_character(get_tree()).get("id", ""))
	for index in characters.size():
		var character := characters[index]
		var id := str(character["id"])
		var owned := Partners.is_owned(get_tree(), id)
		if owned:
			count += 1
		var state := "当前上场" if owned and active == id else ("已拥有" if owned else "未解锁")
		var button := character_buttons[index]
		button.text = "%s   ·   %s" % [str(character.get("name", id)), state]
		button.tooltip_text = button.text
		button.add_theme_stylebox_override("normal", UI.box(Color("#23243D") if id == selected_id else Color("#131C2E"), UI.ACCENT if id == selected_id else Color("#303C57")))
	count_label.text = "%d / %d 已拥有" % [count, characters.size()]

func _choose_partner() -> void:
	if action_button.disabled:
		return
	if Partners.select_character(get_tree(), selected_id):
		_select(selected_id)
		status_label.text = "已将 %s 设为上场角色" % name_label.text
	else:
		status_label.text = "暂时无法保存伙伴选择，请稍后重试"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()

func _back() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")
