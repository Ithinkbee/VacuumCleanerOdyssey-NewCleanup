extends Area2D

var velocity = Vector2.ZERO
var damage = 1
var max_range: float = 400.0

var bounce_count: int = 0
var is_homing: bool = false
var is_big: bool = false

var _prev_position: Vector2 = Vector2.ZERO
var _just_bounced: bool = false
var _traveled: float = 0.0

func _ready():
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)
	body_entered.connect(_on_body_entered)

func apply_flags():
	if Artifacts.has_bullet_flag("bounce"):
		bounce_count = Artifacts.get_bullet_flag("bounce")
	if Artifacts.has_bullet_flag("homing"):
		is_homing = true
	if Artifacts.has_bullet_flag("big"):
		is_big = true
		scale = Vector2(2.2, 2.2)
		damage = int(damage * 2.0)
		velocity *= 0.65

func _physics_process(delta):
	if is_homing:
		_apply_homing(delta)

	_prev_position = global_position
	_just_bounced = false

	var move = velocity * delta
	_traveled += move.length()

	# Уничтожаем пулю если она пролетела максимальную дальность
	if _traveled >= max_range:
		queue_free()
		return

	var step_size = 8.0
	var steps = max(1, int(move.length() / step_size))
	var step = move / steps
	for i in steps:
		position += step

func _apply_homing(delta):
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist = INF
	for e in enemies:
		var d = global_position.distance_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	if nearest and nearest_dist < 400.0:
		var desired = (nearest.global_position - global_position).normalized()
		var current_dir = velocity.normalized()
		var new_dir = current_dir.lerp(desired, delta * 3.5).normalized()
		velocity = new_dir * velocity.length()

func _on_body_entered(body):
	if not is_in_group("enemy_projectile"):
		if body.is_in_group("enemies"):
			body.take_damage(damage)
			queue_free()
			return
	else:
		if body.is_in_group("player"):
			body.take_damage(1)
			queue_free()
			return

	if body.is_in_group("walls"):
		if bounce_count > 0 and not _just_bounced:
			_bounce_off_wall(body)
		else:
			queue_free()

func _bounce_off_wall(wall):
	bounce_count -= 1
	_just_bounced = true
	var hit_normal = _get_wall_normal(wall)
	velocity = velocity.bounce(hit_normal)
	global_position = _prev_position

func _get_wall_normal(wall: Node) -> Vector2:
	var dir = velocity.normalized()
	if wall is StaticBody2D or wall is TileMapLayer or wall is TileMap:
		var to_bullet = (global_position - wall.global_position).normalized()
		if abs(to_bullet.x) > abs(to_bullet.y):
			return Vector2(sign(to_bullet.x), 0)
		else:
			return Vector2(0, sign(to_bullet.y))
	if abs(dir.x) > abs(dir.y):
		return Vector2(-sign(dir.x), 0)
	else:
		return Vector2(0, -sign(dir.y))
