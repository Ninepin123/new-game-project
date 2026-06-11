extends Control

const Sfx := preload("res://scripts/sfx.gd")
const GAME_SCENE := "res://scenes/level_select.tscn"
const BACKGROUND_TEXTURE := preload("res://textures/bg_texture.png")
const HERO_TEXTURE := preload("res://main_character.png")

var _title_label: Label
var _subtitle_label: Label
var _hero_preview: TextureRect
var _hero_slot: Control
var _start_button: Button
var _quit_button: Button

func _ready() -> void:
	_build_ui()
	resized.connect(_update_responsive_layout)
	_start_button.pressed.connect(_start_game)
	_quit_button.pressed.connect(_quit_game)
	_start_button.grab_focus()
	_update_responsive_layout()
	_play_idle_animation()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_start_game()
	elif event.is_action_pressed("ui_cancel"):
		_quit_game()

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var background := TextureRect.new()
	background.name = "Background"
	background.texture = BACKGROUND_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var overlay := ColorRect.new()
	overlay.name = "Overlay"
	overlay.color = Color(0.03, 0.07, 0.12, 0.48)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var margin := MarginContainer.new()
	margin.name = "ContentMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 36)
	add_child(margin)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 18)
	margin.add_child(content)

	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.text = "小仙子大作戰"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.add_theme_font_size_override("font_size", 64)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	_title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.55))
	_title_label.add_theme_constant_override("shadow_offset_x", 3)
	_title_label.add_theme_constant_override("shadow_offset_y", 4)
	content.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.name = "Subtitle"
	_subtitle_label.text = "準備好展開冒險了嗎？"
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_subtitle_label.add_theme_font_size_override("font_size", 24)
	_subtitle_label.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0))
	content.add_child(_subtitle_label)

	# 用一個固定尺寸的外框 Control 佔住 VBox 版位，仙子圖在外框內自由上下浮動，
	# 避免直接對「容器管理的子節點」做 position 動畫而與版面排版搶位（會導致重進場景時跑位）。
	_hero_slot = Control.new()
	_hero_slot.name = "HeroSlot"
	_hero_slot.custom_minimum_size = Vector2(220, 230)
	_hero_slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hero_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_hero_slot)

	_hero_preview = TextureRect.new()
	_hero_preview.name = "HeroPreview"
	_hero_preview.texture = _make_first_frame_texture()
	_hero_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hero_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hero_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hero_preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hero_slot.add_child(_hero_preview)

	var button_box := VBoxContainer.new()
	button_box.name = "Buttons"
	button_box.alignment = BoxContainer.ALIGNMENT_CENTER
	button_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button_box.add_theme_constant_override("separation", 12)
	content.add_child(button_box)

	_start_button = _make_menu_button("開始遊戲", "StartButton")
	button_box.add_child(_start_button)

	_quit_button = _make_menu_button("離開遊戲", "QuitButton")
	button_box.add_child(_quit_button)

func _make_first_frame_texture() -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = HERO_TEXTURE
	atlas.region = Rect2(0, 0, HERO_TEXTURE.get_width() / 4.0, HERO_TEXTURE.get_height())
	return atlas

func _make_menu_button(text: String, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = Vector2(240, 58)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	button.add_theme_color_override("font_focus_color", Color(1.0, 1.0, 1.0))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.14, 0.45, 0.62)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.18, 0.58, 0.76)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.08, 0.31, 0.44)))
	button.add_theme_stylebox_override("focus", _button_style(Color(0.35, 0.72, 0.88), 4, Color(1.0, 0.94, 0.48)))
	return button

func _button_style(color: Color, border_width := 0, border_color := Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = border_color
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	style.shadow_size = 8
	style.content_margin_left = 22
	style.content_margin_right = 22
	return style

func _update_responsive_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var compact := viewport_size.y < 560.0 or viewport_size.x < 520.0
	_subtitle_label.visible = not compact
	_hero_slot.visible = not compact
	_hero_slot.custom_minimum_size = Vector2(180, 190) if viewport_size.y < 700.0 else Vector2(220, 230)

func _play_idle_animation() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(_hero_preview, "position:y", -8.0, 1.0) \
		.as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_hero_preview, "position:y", 8.0, 1.0) \
		.as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _start_game() -> void:
	# 音效節點掛在 root 下，不會因場景切換被中斷
	Sfx.play(self, "game_start", -3.0)
	get_tree().change_scene_to_file(GAME_SCENE)

func _quit_game() -> void:
	get_tree().quit()
