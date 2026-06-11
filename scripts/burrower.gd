extends CharacterBody2D
## 地洞爬行獸。
## 行為：平時偽裝成土堆藏在地底（無碰撞、不可踩）；玩家靠近時破土而出，
## 探頭後開始緩慢追擊，貼近玩家時張嘴撕咬；玩家離開範圍便縮回地底。
## 互動：鑽出期間被玩家從上方踩到 → 翻肚死亡；從側面碰到 → 傷害玩家。

const Sfx := preload("res://scripts/sfx.gd")

const GRAVITY := 980.0
const CHASE_SPEED := 55.0
const EDGE_OFFSET := 40.0
const DETECT_RANGE := 240.0
const DETECT_HEIGHT := 130.0
const LOSE_RANGE := 420.0
const EMERGE_TIME := 0.3
const PEEK_TIME := 0.25
const BITE_RANGE := 64.0
const BITE_TIME := 0.5
const BITE_REST := 0.3
const RETREAT_TIME := 0.35
const WALK_FPS := 5.0
const DEFAULT_SPRITE_OFFSET := Vector2(0.0, -29.0)
const HIDDEN_SPRITE_OFFSET := Vector2(0.0, 10.0)

const TEX := {
	"hidden": preload("res://textures/mobs/burrower/burrower_hidden.png"),
	"emerge": preload("res://textures/mobs/burrower/burrower_emerge.png"),
	"peek": preload("res://textures/mobs/burrower/burrower_peek.png"),
	"walk1": preload("res://textures/mobs/burrower/burrower_walk1.png"),
	"walk2": preload("res://textures/mobs/burrower/burrower_walk2.png"),
	"bite": preload("res://textures/mobs/burrower/burrower_bite.png"),
	"retreat": preload("res://textures/mobs/burrower/burrower_retreat.png"),
	"dead": preload("res://textures/mobs/burrower/burrower_dead.png"),
}

enum State { HIDDEN, EMERGING, PEEK, CHASE, BITE, REST, RETREAT, DEAD }

var _state := State.HIDDEN
var _timer := 0.0
var _facing := -1
var _anim_time := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var ledge_ray: RayCast2D = $LedgeRay
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	add_to_group("enemy")
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	_set_active_collision(false)
	_show_frame("hidden")

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	if _state == State.DEAD:
		velocity.x = 0.0
		move_and_slide()
		return

	var player := _find_player()
	match _state:
		State.HIDDEN:
			velocity.x = 0.0
			sprite.flip_h = false
			if player != null:
				var to := player.global_position - global_position
				if absf(to.x) < DETECT_RANGE and absf(to.y) < DETECT_HEIGHT:
					_facing = -1 if to.x < 0.0 else 1
					_state = State.EMERGING
					_timer = EMERGE_TIME
					_show_frame("emerge")
		State.EMERGING:
			velocity.x = 0.0
			_timer -= delta
			if _timer <= 0.0:
				_state = State.PEEK
				_timer = PEEK_TIME
				_show_frame("peek")
		State.PEEK:
			velocity.x = 0.0
			_timer -= delta
			if _timer <= 0.0:
				_state = State.CHASE
				_anim_time = 0.0
				_set_active_collision(true)
		State.CHASE:
			_chase(delta, player)
		State.BITE:
			velocity.x = 0.0
			_timer -= delta
			if _timer <= 0.0:
				_state = State.REST
				_timer = BITE_REST
				_show_frame("peek")
		State.REST:
			velocity.x = 0.0
			_timer -= delta
			if _timer <= 0.0:
				_state = State.CHASE
				_anim_time = 0.0
		State.RETREAT:
			velocity.x = 0.0
			_timer -= delta
			if _timer <= 0.0:
				_state = State.HIDDEN
				_show_frame("hidden")

	move_and_slide()
	if _state != State.HIDDEN and _state != State.RETREAT:
		sprite.flip_h = _facing > 0

func _chase(delta: float, player: Node2D) -> void:
	if player == null:
		_start_retreat()
		return
	var to := player.global_position - global_position
	if absf(to.x) > LOSE_RANGE:
		_start_retreat()
		return
	_facing = -1 if to.x < 0.0 else 1
	if absf(to.x) <= BITE_RANGE:
		velocity.x = 0.0
		_state = State.BITE
		_timer = BITE_TIME
		_show_frame("bite")
		return
	# 追擊：前方沒有地面就停下，不會自己走下平台
	ledge_ray.position.x = EDGE_OFFSET * float(_facing)
	if is_on_floor() and not ledge_ray.is_colliding():
		velocity.x = 0.0
		_show_frame("peek")
	else:
		velocity.x = float(_facing) * CHASE_SPEED
		_anim_time += delta
		_show_frame("walk1" if int(_anim_time * WALK_FPS) % 2 == 0 else "walk2")

func _start_retreat() -> void:
	_state = State.RETREAT
	_timer = RETREAT_TIME
	velocity.x = 0.0
	_show_frame("retreat")
	_set_active_collision(false)

## 鑽出時才有實體碰撞與傷害／踩踏判定；藏在地底時只是無害的土堆。
func _set_active_collision(active: bool) -> void:
	set_deferred("collision_layer", 4 if active else 0)
	hitbox.set_deferred("monitoring", active)

func _find_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	return players[0] if players.size() > 0 else null

func _show_frame(frame_name: String) -> void:
	sprite.texture = TEX[frame_name]
	sprite.offset = HIDDEN_SPRITE_OFFSET if frame_name == "hidden" else DEFAULT_SPRITE_OFFSET

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
	Sfx.play(self, "stomp", -4.0)
	set_deferred("collision_layer", 0)
	hitbox.set_deferred("monitoring", false)
	_show_frame("dead")
	var tw := create_tween()
	tw.tween_interval(0.6)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.35)
	tw.tween_callback(queue_free)
