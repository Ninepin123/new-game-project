extends Area2D
## 超級蘑菇道具：玩家碰到後讓玩家變大（grow）。

var _collected := false

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# 輕微上下浮動，讓道具更顯眼
	var bob := create_tween().set_loops()
	bob.tween_property(sprite, "position:y", sprite.position.y - 4.0, 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(sprite, "position:y", sprite.position.y, 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_body_entered(body: Node) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	if body.has_method("grow"):
		body.grow()
	# 收集動畫後移除
	set_deferred("monitoring", false)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(queue_free)
