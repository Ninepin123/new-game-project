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
		"name": "第一關 · 新手上路",
		"platforms": [
			{"x": -260.0, "y": 360.0, "w": 200.0},
			{"x": 240.0, "y": 360.0, "w": 200.0},
		],
		"enemies": [Vector2(-250.0, 421.0), Vector2(350.0, 421.0)],
		"lizards": [Vector2(620.0, 418.0)],
		"burrowers": [Vector2(850.0, 416.0)],
		"mushrooms": [Vector2(120.0, 430.0)],
		"goal_x": 1080.0,
	},
	{
		"name": "第二關 · 跳躍試煉",
		"platforms": [
			{"x": -420.0, "y": 370.0, "w": 180.0},
			{"x": -120.0, "y": 290.0, "w": 180.0},
			{"x": 200.0, "y": 220.0, "w": 180.0},
			{"x": 520.0, "y": 300.0, "w": 180.0},
		],
		"enemies": [Vector2(-280.0, 421.0), Vector2(180.0, 421.0), Vector2(620.0, 421.0)],
		"lizards": [Vector2(850.0, 418.0)],
		"burrowers": [Vector2(420.0, 416.0)],
		"mushrooms": [Vector2(320.0, 430.0)],
		"goal_x": 1080.0,
	},
	{
		"name": "第三關 · 魔王關卡",
		"platforms": [
			{"x": -520.0, "y": 360.0, "w": 160.0},
			{"x": -260.0, "y": 270.0, "w": 160.0},
			{"x": 20.0, "y": 200.0, "w": 160.0},
			{"x": 300.0, "y": 270.0, "w": 160.0},
			{"x": 600.0, "y": 360.0, "w": 160.0},
		],
		"enemies": [
			Vector2(-360.0, 421.0), Vector2(180.0, 421.0),
			Vector2(430.0, 421.0), Vector2(680.0, 421.0),
		],
		"lizards": [Vector2(-250.0, 418.0), Vector2(940.0, 418.0)],
		"burrowers": [Vector2(300.0, 416.0), Vector2(820.0, 416.0)],
		"mushrooms": [Vector2(20.0, 175.0)],
		"goal_x": 1080.0,
	},
]
