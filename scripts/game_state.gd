extends Node
## 全域遊戲狀態（autoload）。
## 記錄玩家在「關卡選擇器」選到的關卡，並提供每一關的版面配置資料給 level.gd 動態生成。
##
## 座標系：Y 向下。地面頂面 y=450（玩家腳底落點）。牆面位於 x ±1160 內側。
## platforms：{x:中心x, y:平台頂面y, w:寬度}
## enemies／lizards／burrowers／mushrooms：Vector2 出生座標
## （enemies=栗寶寶、lizards=跳躍蜥蜴怪、burrowers=地洞爬行獸）

const TOTAL_LEVELS := 3

var selected_level := 1  # 1..TOTAL_LEVELS

var LEVELS := [
	{
		"name": "第一關 · 魔法森林入口",
		"platforms": [
			{"x": -430.0, "y": 320.0, "w": 220.0},
			{"x": -120.0, "y": 200.0, "w": 180.0},
			{"x": 220.0, "y": 310.0, "w": 220.0},
			{"x": 560.0, "y": 185.0, "w": 180.0},
			{"x": 840.0, "y": 315.0, "w": 180.0},
		],
		"enemies": [Vector2(70.0, 421.0), Vector2(420.0, 421.0)],
		"lizards": [Vector2(760.0, 418.0)],
		"burrowers": [Vector2(940.0, 416.0)],
		"mushrooms": [Vector2(-590.0, 430.0), Vector2(560.0, 160.0)],
		"goal_x": 1080.0,
	},
	{
		"name": "第二關 · 林間跳臺",
		"platforms": [
			{"x": -560.0, "y": 320.0, "w": 180.0},
			{"x": -300.0, "y": 200.0, "w": 160.0},
			{"x": -40.0, "y": 95.0, "w": 150.0},
			{"x": 250.0, "y": 205.0, "w": 170.0},
			{"x": 520.0, "y": 100.0, "w": 150.0},
			{"x": 800.0, "y": 310.0, "w": 210.0},
		],
		"enemies": [Vector2(-690.0, 421.0), Vector2(120.0, 421.0), Vector2(650.0, 421.0)],
		"lizards": [Vector2(820.0, 418.0)],
		"burrowers": [Vector2(420.0, 416.0)],
		"mushrooms": [Vector2(-300.0, 150.0), Vector2(520.0, 50.0)],
		"goal_x": 1080.0,
	},
	{
		"name": "第三關 · 魔王庭院",
		"platforms": [
			{"x": -700.0, "y": 345.0, "w": 150.0},
			{"x": -470.0, "y": 255.0, "w": 130.0},
			{"x": -220.0, "y": 165.0, "w": 125.0},
			{"x": 45.0, "y": 255.0, "w": 130.0},
			{"x": 300.0, "y": 165.0, "w": 120.0},
			{"x": 555.0, "y": 265.0, "w": 130.0},
			{"x": 800.0, "y": 150.0, "w": 120.0},
		],
		"enemies": [
			Vector2(-760.0, 421.0), Vector2(520.0, 421.0),
		],
		"falling_enemies": [
			{"x_min": -360.0, "x_max": -120.0, "y": -140.0, "delay": 0.6, "interval": 1.0},
			{"x_min": -40.0, "x_max": 190.0, "y": -160.0, "delay": 1.0, "interval": 0.8},
			{"x_min": 260.0, "x_max": 500.0, "y": -150.0, "delay": 0.6, "interval": 1.0},
			{"x_min": 600.0, "x_max": 820.0, "y": -170.0, "delay": 0.2, "interval": 1.0},
			{"x_min": 860.0, "x_max": 1040.0, "y": -150.0, "delay": 2.0, "interval": 0.9},
		],
		"lizards": [Vector2(-455.0, 418.0), Vector2(860.0, 418.0)],
		"burrowers": [Vector2(300.0, 416.0), Vector2(990.0, 416.0)],
		"mushrooms": [Vector2(-220.0, 140.0)],
		"goal_x": 1080.0,
	},
]
