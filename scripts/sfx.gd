extends RefCounted
## 一次性音效播放工具。各腳本以 preload 取得後呼叫 static 函式，
## 不註冊 autoload（編輯器開啟期間改 project.godot 容易被編輯器回寫覆蓋）。
##
## 播放節點掛在 root 之下：跨場景切換不會被中斷（如主選單的開始音效）、
## 發音者死亡 queue_free 後音效仍可播完（如踩扁敵人）。
## PROCESS_MODE_ALWAYS 讓死亡／過關面板暫停場景樹時，結算音效照常播放。

const STREAMS := {
	"jump": preload("res://audio/default_jump.mp3"),
	"land_dirt": preload("res://audio/jump_back_on_dirt.mp3"),
	"land_concrete": preload("res://audio/jumping_on_concrete.mp3"),
	"stomp": preload("res://audio/crack_monster.mp3"),
	"power_up": preload("res://audio/power_up.mp3"),
	"game_start": preload("res://audio/game_start.mp3"),
	"game_over": preload("res://audio/game_over.mp3"),
	"victory": preload("res://audio/victory.mp3"),
}


static func play(ctx: Node, sfx_name: String, volume_db: float = 0.0) -> void:
	var stream: AudioStream = STREAMS.get(sfx_name)
	if stream == null or not ctx.is_inside_tree():
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.tree_entered.connect(player.play)
	player.finished.connect(player.queue_free)
	# body_entered 等物理回呼期間不可直接修改場景樹 → 延後到幀末再掛上
	ctx.get_tree().root.add_child.call_deferred(player)
