extends Control
## 關卡選擇器：列出 3 個關卡按鈕，點擊後設定 GameState.selected_level 並進入關卡。

const LEVEL_SCENE := "res://scenes/level.tscn"
const START_MENU := "res://scenes/start_menu.tscn"
const BACKGROUND_TEXTURE := preload("res://textures/bg_texture.png")


func _ready() -> void:
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var background := TextureRect.new()
	background.texture = BACKGROUND_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var overlay := ColorRect.new()
	overlay.color = Color(0.03, 0.07, 0.12, 0.55)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "選擇關卡"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 4)
	vbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	for i in range(GameState.TOTAL_LEVELS):
		var data: Dictionary = GameState.LEVELS[i]
		var label_text: String = str(data.get("name", "關卡 %d" % (i + 1)))
		var btn := _make_button(label_text)
		btn.pressed.connect(_on_level_pressed.bind(i + 1))
		vbox.add_child(btn)
		if i == 0:
			btn.call_deferred("grab_focus")

	var back := _make_button("返回主選單")
	back.pressed.connect(_on_back_pressed)
	vbox.add_child(back)


func _on_level_pressed(level: int) -> void:
	GameState.selected_level = level
	get_tree().change_scene_to_file(LEVEL_SCENE)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(START_MENU)


func _make_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(340, 60)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.focus_mode = Control.FOCUS_ALL
	btn.add_theme_font_size_override("font_size", 26)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_focus_color", Color(1, 1, 1))
	btn.add_theme_stylebox_override("normal", _button_style(Color(0.14, 0.45, 0.62)))
	btn.add_theme_stylebox_override("hover", _button_style(Color(0.18, 0.58, 0.76)))
	btn.add_theme_stylebox_override("pressed", _button_style(Color(0.08, 0.31, 0.44)))
	btn.add_theme_stylebox_override("focus", _button_style(Color(0.35, 0.72, 0.88), 4, Color(1.0, 0.94, 0.48)))
	return btn


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
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
