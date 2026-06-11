extends Node2D
## 可重複使用的關卡場景。
## 依 GameState.selected_level 動態生成平台、敵人、蘑菇與終點旗，
## 並提供「你輸了」死亡畫面（含復活按鈕）與「過關！」勝利畫面。

const Sfx := preload("res://scripts/sfx.gd")
const BGM_STREAM := preload("res://audio/background_music.mp3")
const EnemyScene := preload("res://scenes/enemy.tscn")
const LizardScene := preload("res://scenes/lizard.tscn")
const BurrowerScene := preload("res://scenes/burrower.tscn")
const MushroomScene := preload("res://scenes/mushroom.tscn")
const PLATFORM_TEX := preload("res://textures/obstacle_texture.png")
const LEVEL_SELECT := "res://scenes/level_select.tscn"

const GROUND_TOP := 450.0

@onready var _content: Node2D = $Content
@onready var _player: CharacterBody2D = $Player

var _level_index := 1
var _level_data: Dictionary
var _ended := false

var _ui: CanvasLayer
var _death_panel: Control
var _win_panel: Control
var _bgm: AudioStreamPlayer


func _ready() -> void:
	_level_index = clampi(GameState.selected_level, 1, GameState.TOTAL_LEVELS)
	_level_data = GameState.LEVELS[_level_index - 1]
	_build_level()
	_build_ui()
	_start_bgm()
	if not _player.died.is_connected(_on_player_died):
		_player.died.connect(_on_player_died)


func _start_bgm() -> void:
	# const 的屬性不可賦值（parser error），先取到 var 再設 loop（同一共享資源）
	var stream: AudioStreamMP3 = BGM_STREAM
	stream.loop = true
	_bgm = AudioStreamPlayer.new()
	_bgm.stream = stream
	_bgm.volume_db = -12.0
	add_child(_bgm)
	_bgm.play()


# ---------------------------------------------------------------- 關卡內容生成

func _build_level() -> void:
	for p in _level_data.get("platforms", []):
		_spawn_platform(p["x"], p["y"], p["w"])
	for e in _level_data.get("enemies", []):
		var enemy := EnemyScene.instantiate()
		enemy.position = e
		_content.add_child(enemy)
	for l in _level_data.get("lizards", []):
		var lizard := LizardScene.instantiate()
		lizard.position = l
		_content.add_child(lizard)
	for b in _level_data.get("burrowers", []):
		var burrower := BurrowerScene.instantiate()
		burrower.position = b
		_content.add_child(burrower)
	for m in _level_data.get("mushrooms", []):
		var mush := MushroomScene.instantiate()
		mush.position = m
		_content.add_child(mush)
	_spawn_goal(_level_data.get("goal_x", 1080.0))


func _spawn_platform(x: float, y_top: float, w: float) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(x, y_top + 15.0)
	body.add_to_group("concrete")  # 玩家落地時依此群組選擇混凝土落地音

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, 30.0)
	shape.shape = rect
	body.add_child(shape)

	var visual := TextureRect.new()
	visual.texture = PLATFORM_TEX
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual.stretch_mode = TextureRect.STRETCH_TILE
	visual.offset_left = -w / 2.0
	visual.offset_top = -15.0
	visual.offset_right = w / 2.0
	visual.offset_bottom = 15.0
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(visual)

	_content.add_child(body)


func _spawn_goal(goal_x: float) -> void:
	var goal := Area2D.new()
	goal.name = "Goal"
	goal.collision_layer = 0
	goal.collision_mask = 2  # 只偵測玩家（player 的 collision_layer = 2）
	goal.position = Vector2(goal_x, 0.0)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(50.0, 220.0)
	shape.shape = rect
	shape.position = Vector2(0.0, GROUND_TOP - 110.0)
	goal.add_child(shape)

	var pole := ColorRect.new()
	pole.color = Color(0.92, 0.92, 0.96)
	pole.size = Vector2(8.0, 200.0)
	pole.position = Vector2(-4.0, GROUND_TOP - 200.0)
	pole.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goal.add_child(pole)

	var flag := ColorRect.new()
	flag.color = Color(0.95, 0.32, 0.32)
	flag.size = Vector2(50.0, 34.0)
	flag.position = Vector2(4.0, GROUND_TOP - 200.0)
	flag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goal.add_child(flag)

	goal.body_entered.connect(_on_goal_reached)
	_content.add_child(goal)


# ----------------------------------------------------------------------- UI

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 10
	_ui.process_mode = Node.PROCESS_MODE_ALWAYS  # 暫停時 UI 仍可互動
	add_child(_ui)

	var hud := Label.new()
	hud.text = str(_level_data.get("name", "關卡 %d" % _level_index))
	hud.position = Vector2(24.0, 18.0)
	hud.add_theme_font_size_override("font_size", 28)
	hud.add_theme_color_override("font_color", Color(1, 1, 1))
	hud.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	hud.add_theme_constant_override("shadow_offset_x", 2)
	hud.add_theme_constant_override("shadow_offset_y", 2)
	_ui.add_child(hud)

	_death_panel = _build_panel("你輸了", Color(1.0, 0.45, 0.45), [
		{"text": "復活", "action": _revive},
		{"text": "返回選關", "action": _go_to_select},
	])

	var win_buttons: Array = []
	if _level_index < GameState.TOTAL_LEVELS:
		win_buttons.append({"text": "下一關", "action": _next_level})
	win_buttons.append({"text": "再玩一次", "action": _revive})
	win_buttons.append({"text": "返回選關", "action": _go_to_select})
	_win_panel = _build_panel("過關！", Color(1.0, 0.92, 0.45), win_buttons)


func _build_panel(title_text: String, title_color: Color, button_specs: Array) -> Control:
	var panel := Control.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	_ui.add_child(panel)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 76)
	title.add_theme_color_override("font_color", title_color)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 4)
	vbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	for spec in button_specs:
		var btn := _make_button(spec["text"])
		btn.pressed.connect(spec["action"])
		vbox.add_child(btn)

	return panel


func _make_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(280, 60)
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
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


# ------------------------------------------------------------------- 流程控制

func _on_player_died() -> void:
	if _ended:
		return
	_ended = true
	_bgm.stop()
	Sfx.play(self, "game_over", -3.0)
	_show_panel(_death_panel)


func _on_goal_reached(body: Node) -> void:
	if _ended or not body.is_in_group("player"):
		return
	_ended = true
	_bgm.stop()
	Sfx.play(self, "victory", -3.0)
	_show_panel(_win_panel)


func _show_panel(panel: Control) -> void:
	panel.visible = true
	get_tree().paused = true
	# 顯示後再取得焦點，讓玩家可用滑鼠點擊或 Enter/方向鍵操作按鈕。
	var btn := _find_first_button(panel)
	if btn != null:
		btn.grab_focus()


func _find_first_button(node: Node) -> Button:
	for child in node.get_children():
		if child is Button:
			return child
		var found := _find_first_button(child)
		if found != null:
			return found
	return null


func _revive() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _next_level() -> void:
	GameState.selected_level = mini(_level_index + 1, GameState.TOTAL_LEVELS)
	get_tree().paused = false
	get_tree().reload_current_scene()


func _go_to_select() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(LEVEL_SELECT)
