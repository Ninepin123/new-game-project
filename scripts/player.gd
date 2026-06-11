extends CharacterBody2D

## 玩家死亡時發出，由 level.gd 接收以顯示「你輸了」死亡畫面。
signal died

const Sfx := preload("res://scripts/sfx.gd")
const WALK_STREAM := preload("res://audio/walking.mp3")
const MagicProjectileScene := preload("res://scenes/magic_projectile.tscn")

const SPEED := 220.0
const JUMP_VELOCITY := -520.0
const STOMP_BOUNCE := -300.0
const LAND_SFX_MIN_FALL_SPEED := 150.0  # 出生小幅落地不出聲，跳躍／墜落才會
const MAGIC_COOLDOWN := 0.35
const STOMP_GRACE_TIME := 0.16

# 小／大兩種狀態的外觀與碰撞尺寸
const SMALL_SCALE := Vector2(0.28, 0.28)
const BIG_SCALE := Vector2(0.42, 0.42)
const SMALL_BODY := Vector2(45, 82)
const BIG_BODY := Vector2(64, 115)

var anim_time := 0.0
const ANIM_SPEED := 8.0 # Frames per second

var is_big := false
var invulnerable := false
var _dead := false
var _was_on_floor := false
var _facing := 1
var _magic_cooldown := 0.0
var _grow_pending := false
var _stomp_grace := 0.0

var _walk_sfx: AudioStreamPlayer

@onready var sprite: Sprite2D = $Sprite2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	body_shape.shape = body_shape.shape.duplicate()
	_reset_to_small_size()
	add_to_group("player")
	# const 的屬性不可賦值（parser error），先取到 var 再設 loop（同一共享資源）
	var walk_stream: AudioStreamMP3 = WALK_STREAM
	walk_stream.loop = true
	_walk_sfx = AudioStreamPlayer.new()
	_walk_sfx.stream = walk_stream
	_walk_sfx.volume_db = -10.0
	add_child(_walk_sfx)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	_magic_cooldown = maxf(_magic_cooldown - delta, 0.0)
	_stomp_grace = maxf(_stomp_grace - delta, 0.0)

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		Sfx.play(self, "jump", -6.0)

	if InputMap.has_action("attack") and Input.is_action_just_pressed("attack"):
		_shoot_magic()

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0.0:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0.0
		_facing = -1 if direction < 0.0 else 1
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

	var fall_speed := velocity.y
	move_and_slide()
	_update_ground_sfx(fall_speed)
	_try_pending_grow()

## 落地音與走路循環音
func _update_ground_sfx(fall_speed: float) -> void:
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor and fall_speed > LAND_SFX_MIN_FALL_SPEED:
		Sfx.play(self, _landing_sfx_name(), -6.0)
	_was_on_floor = on_floor

	var walking: bool = on_floor and absf(velocity.x) > 20.0
	if walking and not _walk_sfx.playing:
		_walk_sfx.play()
	elif not walking and _walk_sfx.playing:
		_walk_sfx.stop()

## 落在平台（concrete 群組）與泥土地面播不同音效
func _landing_sfx_name() -> String:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider: Object = col.get_collider()
		if col.get_normal().y < -0.5 and collider is Node and (collider as Node).is_in_group("concrete"):
			return "land_concrete"
	return "land_dirt"

## 踩踏敵人後的彈跳
func bounce() -> void:
	_stomp_grace = STOMP_GRACE_TIME
	velocity.y = STOMP_BOUNCE

func can_take_enemy_contact_damage() -> bool:
	return _stomp_grace <= 0.0

func _reset_to_small_size() -> void:
	is_big = false
	_grow_pending = false
	sprite.scale = SMALL_SCALE
	var rect := body_shape.shape as RectangleShape2D
	rect.size = SMALL_BODY

func _shoot_magic() -> void:
	if _magic_cooldown > 0.0:
		return
	_magic_cooldown = MAGIC_COOLDOWN
	var projectile := MagicProjectileScene.instantiate()
	projectile.global_position = global_position + Vector2(42.0 * float(_facing), -24.0)
	projectile.setup(_facing)
	get_tree().current_scene.add_child(projectile)

## 吃到蘑菇 → 變大
func grow() -> void:
	if is_big:
		return
	if not _has_room_for_body(BIG_BODY):
		_grow_pending = true
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

func _try_pending_grow() -> void:
	if not _grow_pending or is_big:
		return
	if not _has_room_for_body(BIG_BODY):
		return
	_grow_pending = false
	is_big = true
	_apply_size(true)

func _has_room_for_body(body_size: Vector2) -> bool:
	var current_rect := body_shape.shape as RectangleShape2D
	var test_shape := RectangleShape2D.new()
	test_shape.size = body_size

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = test_shape
	params.transform = Transform2D(0.0, global_position - Vector2(0.0, (body_size.y - current_rect.size.y) * 0.5))
	params.collision_mask = collision_mask
	params.exclude = [get_rid()]

	return get_world_2d().direct_space_state.intersect_shape(params, 8).is_empty()

func _start_invulnerability() -> void:
	invulnerable = true
	var tw := create_tween().set_loops(6)
	tw.tween_property(sprite, "modulate:a", 0.3, 0.08)
	tw.tween_property(sprite, "modulate:a", 1.0, 0.08)
	await tw.finished
	sprite.modulate.a = 1.0
	invulnerable = false

func _die() -> void:
	if _dead:
		return
	_dead = true
	velocity = Vector2.ZERO
	_walk_sfx.stop()
	create_tween().tween_property(sprite, "modulate:a", 0.0, 0.45)
	await get_tree().create_timer(0.55).timeout
	died.emit()
