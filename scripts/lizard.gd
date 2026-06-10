extends CharacterBody2D
## 跳躍蜥蜴怪。
## 行為：地面巡邏；玩家進入偵測範圍時驚覺（頭上冒「!」）短暫蓄力，
## 接著朝玩家方向跳撲，落地揚起塵土後繼續巡邏（有偵測冷卻避免連跳）。
## 互動：被玩家從上方踩到 → 死亡；從側面碰到 → 傷害玩家。

const SPEED := 60.0
const GRAVITY := 980.0
const EDGE_OFFSET := 36.0
const DETECT_RANGE := 250.0
const DETECT_HEIGHT := 90.0
const JUMP_VX := 210.0
const JUMP_VY := -380.0
const SPOT_TIME := 0.45
const LAND_TIME := 0.35
const DETECT_COOLDOWN := 1.6
const WALK_FPS := 6.0

const TEX := {
	"walk1": preload("res://textures/mobs/lizard/lizard_walk1.png"),
	"walk2": preload("res://textures/mobs/lizard/lizard_walk2.png"),
	"spot": preload("res://textures/mobs/lizard/lizard_spot.png"),
	"takeoff": preload("res://textures/mobs/lizard/lizard_takeoff.png"),
	"air": preload("res://textures/mobs/lizard/lizard_air.png"),
	"land": preload("res://textures/mobs/lizard/lizard_land.png"),
	"dead": preload("res://textures/mobs/lizard/lizard_dead.png"),
}

enum State { PATROL, SPOT, AIR, LAND, DEAD }

@export var direction := -1  # -1 = 向左, 1 = 向右

var _state := State.PATROL
var _timer := 0.0
var _cooldown := 0.0
var _anim_time := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var ledge_ray: RayCast2D = $LedgeRay
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	add_to_group("enemy")
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	sprite.texture = TEX.walk1

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	if _state == State.DEAD:
		velocity.x = 0.0
		move_and_slide()
		return

	_cooldown = maxf(_cooldown - delta, 0.0)
	match _state:
		State.PATROL:
			_patrol(delta)
		State.SPOT:
			_spot(delta)
		State.AIR:
			_air()
		State.LAND:
			_land(delta)

	move_and_slide()

	# 巡邏時碰牆轉向（依牆面法線決定新方向，避免抖動）
	if _state == State.PATROL and is_on_wall():
		var nx := get_wall_normal().x
		if nx != 0.0:
			direction = int(signf(nx))

	sprite.flip_h = direction > 0

func _patrol(delta: float) -> void:
	velocity.x = float(direction) * SPEED
	ledge_ray.position.x = EDGE_OFFSET * float(direction)
	if is_on_floor() and not ledge_ray.is_colliding():
		direction = -direction
	_anim_time += delta
	sprite.texture = TEX.walk1 if int(_anim_time * WALK_FPS) % 2 == 0 else TEX.walk2

	if _cooldown > 0.0 or not is_on_floor():
		return
	var player := _find_player()
	if player == null:
		return
	var to := player.global_position - global_position
	if absf(to.x) < DETECT_RANGE and absf(to.y) < DETECT_HEIGHT:
		direction = -1 if to.x < 0.0 else 1
		velocity.x = 0.0
		_state = State.SPOT
		_timer = SPOT_TIME
		sprite.texture = TEX.spot

func _spot(delta: float) -> void:
	velocity.x = 0.0
	_timer -= delta
	if _timer <= 0.0:
		_state = State.AIR
		velocity = Vector2(float(direction) * JUMP_VX, JUMP_VY)
		sprite.texture = TEX.takeoff

func _air() -> void:
	# 上升初段保留起跳格，之後切換為空中撲擊格
	if velocity.y > -200.0:
		sprite.texture = TEX.air
	if is_on_floor():
		_state = State.LAND
		_timer = LAND_TIME
		velocity.x = 0.0
		sprite.texture = TEX.land

func _land(delta: float) -> void:
	velocity.x = 0.0
	_timer -= delta
	if _timer <= 0.0:
		_state = State.PATROL
		_cooldown = DETECT_COOLDOWN
		_anim_time = 0.0

func _find_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	return players[0] if players.size() > 0 else null

func _on_hitbox_body_entered(body: Node) -> void:
	if _state == State.DEAD or not body.is_in_group("player"):
		return
	# 踩踏判定：玩家中心位於敵人中心上方，且正在明顯下落（避免走路誤判）
	var stomping: bool = body.velocity.y > 40.0 and body.global_position.y < global_position.y
	if stomping:
		_die()
		if body.has_method("bounce"):
			body.bounce()
	elif body.has_method("hit"):
		body.hit()

func _die() -> void:
	_state = State.DEAD
	velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	hitbox.set_deferred("monitoring", false)
	sprite.texture = TEX.dead
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.35)
	tw.tween_callback(queue_free)
