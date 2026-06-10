extends CharacterBody2D

const SPEED := 220.0
const JUMP_VELOCITY := -420.0
const STOMP_BOUNCE := -300.0

# 小／大兩種狀態的外觀與碰撞尺寸
const SMALL_SCALE := Vector2(0.375, 0.375)
const BIG_SCALE := Vector2(0.55, 0.55)
const SMALL_BODY := Vector2(60, 110)
const BIG_BODY := Vector2(84, 150)

var anim_time := 0.0
const ANIM_SPEED := 8.0 # Frames per second

var is_big := false
var invulnerable := false
var _dead := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if _dead:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0.0:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	# Animation logic
	if is_on_floor():
		if velocity.x != 0.0:
			anim_time += delta
			sprite.frame = int(anim_time * ANIM_SPEED) % 4
		else:
			anim_time = 0.0
			sprite.frame = 0 # Idle frame
	else:
		# Jump/Fall frame
		sprite.frame = 2

	move_and_slide()

## 踩踏敵人後的彈跳
func bounce() -> void:
	velocity.y = STOMP_BOUNCE

## 吃到蘑菇 → 變大
func grow() -> void:
	if is_big:
		return
	is_big = true
	_apply_size(true)

## 被敵人傷害：大→變小並短暫無敵；小→死亡
func hit() -> void:
	if invulnerable or _dead:
		return
	if is_big:
		is_big = false
		_apply_size(false)
		_start_invulnerability()
	else:
		_die()

func _apply_size(big: bool) -> void:
	var target_scale: Vector2 = BIG_SCALE if big else SMALL_SCALE
	var body_size: Vector2 = BIG_BODY if big else SMALL_BODY
	var rect := body_shape.shape as RectangleShape2D
	# 維持腳底位置：依高度差移動原點
	position.y -= (body_size.y - rect.size.y) * 0.5
	rect.size = body_size
	create_tween().tween_property(sprite, "scale", target_scale, 0.15) \
		.set_trans(Tween.TRANS_BACK)

func _start_invulnerability() -> void:
	invulnerable = true
	var tw := create_tween().set_loops(6)
	tw.tween_property(sprite, "modulate:a", 0.3, 0.08)
	tw.tween_property(sprite, "modulate:a", 1.0, 0.08)
	await tw.finished
	sprite.modulate.a = 1.0
	invulnerable = false

func _die() -> void:
	_dead = true
	velocity = Vector2.ZERO
	create_tween().tween_property(sprite, "modulate:a", 0.0, 0.5)
	await get_tree().create_timer(0.8).timeout
	get_tree().reload_current_scene()
