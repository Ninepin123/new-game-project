extends Area2D
## 玩家發射的魔法球。
## 呼叫 setup() 設定飛行方向後，碰到敵人或場景碰撞物就消失。

const SPEED := 520.0
const MAX_LIFETIME := 1.8

var direction := Vector2.RIGHT
var _lifetime := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func setup(facing: int) -> void:
	direction = Vector2.RIGHT if facing >= 0 else Vector2.LEFT
	scale.x = absf(scale.x) * float(facing)


func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	_lifetime += delta
	if _lifetime >= MAX_LIFETIME:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy") and body.has_method("take_magic_hit"):
		body.take_magic_hit()
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	var owner := area.get_parent()
	if owner != null and owner.is_in_group("enemy") and owner.has_method("take_magic_hit"):
		owner.take_magic_hit()
		queue_free()
