extends CharacterBody2D
## 敵對生物（栗寶寶風格）。
## 行為：在地面左右巡邏，碰到牆壁或走到平台邊緣會自動轉向。
## 互動：被玩家從上方踩到 → 壓扁死亡並讓玩家彈跳；從側面碰到 → 傷害玩家。

const Sfx := preload("res://scripts/sfx.gd")

const SPEED := 70.0
const GRAVITY := 980.0
const EDGE_OFFSET := 30.0

@export var direction := -1  # -1 = 向左, 1 = 向右

var _dead := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var ledge_ray: RayCast2D = $LedgeRay
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	add_to_group("enemy")
	hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	if _dead:
		return

	velocity.y += GRAVITY * delta
	velocity.x = float(direction) * SPEED

	# 平台邊緣偵測：射線放在前進方向前方，腳下沒地面就轉向
	ledge_ray.position.x = EDGE_OFFSET * float(direction)
	if is_on_floor() and not ledge_ray.is_colliding():
		direction = -direction

	move_and_slide()

	# 碰牆轉向（依牆面法線決定新方向，避免抖動）
	if is_on_wall():
		var nx := get_wall_normal().x
		if nx != 0.0:
			direction = int(signf(nx))

	sprite.flip_h = direction > 0

func _on_hitbox_body_entered(body: Node) -> void:
	if _dead or not body.is_in_group("player"):
		return
	# 踩踏判定：玩家中心位於敵人中心上方，且正在明顯下落（避免走路誤判）
	var stomping: bool = body.velocity.y > 40.0 and body.global_position.y < global_position.y
	if stomping:
		_squash()
		if body.has_method("bounce"):
			body.bounce()
	elif body.has_method("hit"):
		body.hit()

func _squash() -> void:
	_dead = true
	velocity = Vector2.ZERO
	Sfx.play(self, "stomp", -4.0)
	set_deferred("collision_layer", 0)
	hitbox.set_deferred("monitoring", false)
	var tw := create_tween()
	tw.tween_property(sprite, "scale:y", sprite.scale.y * 0.12, 0.08)
	tw.parallel().tween_property(sprite, "modulate:a", 0.0, 0.2)
	tw.tween_callback(queue_free)
