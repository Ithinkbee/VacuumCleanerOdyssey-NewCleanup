extends CharacterBody2D

@export var projectile_scene: PackedScene

@onready var speed = Config.get_val("player", "speed", 250.0)
@onready var max_hp = Config.get_val("player", "hp", 6)
@onready var shoot_delay = Config.get_val("player", "shoot_delay", 0.4)
@onready var damage = Config.get_val("player", "damage", 5)
@onready var invincibility_duration = Config.get_val("player", "invincibility_time", 1.0)
@onready var bullet_range = Config.get_val("player", "bullet_range", 400.0)

var is_invincible: bool = false
var current_hp: int
var can_shoot: bool = true

# Активная способность
var active_cooldown_remaining: float = 0.0
var can_use_active: bool = true

# Рестарт
var _restart_hold_time: float = 0.0
const RESTART_HOLD_DURATION: float = 3.0
var _restarting: bool = false

# ── ЯРОСТЬ ──────────────────────────────────────────────────────
var rage: float = 0.0
var is_raging: bool = false
var _rage_decay_timer: float = 0.0  # сколько прошло с последнего события

# Настройки из конфига
@onready var rage_max        = Config.get_val("rage", "max_rage",          100.0)
@onready var rage_kill_gain  = Config.get_val("rage", "kill_gain",          18.0)
@onready var rage_dmg_gain   = Config.get_val("rage", "damage_gain",        25.0)
@onready var rage_decay_delay = Config.get_val("rage", "decay_delay",        4.0)
@onready var rage_decay_rate  = Config.get_val("rage", "decay_rate",          8.0)
@onready var rage_duration    = Config.get_val("rage", "duration",            7.0)
@onready var rage_dmg_mult    = Config.get_val("rage", "damage_mult",         2.0)
@onready var rage_speed_mult  = Config.get_val("rage", "speed_mult",          2.0)
@onready var rage_shoot_mult  = Config.get_val("rage", "shoot_delay_mult",    0.5)

var rage_gain_mult: float = 1.0  # модифицируется артефактом "Красная тряпка"

signal health_changed(current_hp, max_hp)
signal active_cooldown_updated(remaining, total)
signal rage_changed(current_rage, max_rage)

func _ready():
	current_hp = max_hp
	health_changed.emit(current_hp, max_hp)
	add_to_group("player")

func _physics_process(delta):
	if Game.current_state != Game.GameState.PLAYING:
		return

	handle_restart_input(delta)

	if not _restarting:
		handle_movement()
		handle_shooting()
		handle_active_input()
		handle_rage_input()
		_update_rage(delta)

	if not can_use_active:
		active_cooldown_remaining -= delta
		if active_cooldown_remaining <= 0.0:
			active_cooldown_remaining = 0.0
			can_use_active = true
		var data = Artifacts.get_data(Artifacts.active_artifact)
		var total = data.get("effect", {}).get("cooldown", 1.0)
		active_cooldown_updated.emit(active_cooldown_remaining, total)

func handle_movement():
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var current_speed = speed * (rage_speed_mult if is_raging else 1.0)

	if direction != Vector2.ZERO:
		velocity = direction * current_speed
		$Sprite2D.rotation = direction.angle()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, current_speed * 0.2)

	move_and_slide()

func handle_shooting():
	var shoot_dir = Vector2.ZERO
	if Input.is_action_pressed("shoot_up"):    shoot_dir.y = -1
	elif Input.is_action_pressed("shoot_down"): shoot_dir.y = 1
	elif Input.is_action_pressed("shoot_left"): shoot_dir.x = -1
	elif Input.is_action_pressed("shoot_right"): shoot_dir.x = 1

	if shoot_dir != Vector2.ZERO and can_shoot:
		shoot(shoot_dir)

func handle_active_input():
	if Input.is_action_just_pressed("use_active") and can_use_active:
		if Artifacts.active_artifact != "":
			use_active(Artifacts.active_artifact)

func handle_rage_input():
	if Input.is_action_just_pressed("rage") and not is_raging:
		if rage >= rage_max:
			_activate_rage()

# ── ШКАЛА ЯРОСТИ ────────────────────────────────────────────────

func _update_rage(delta):
	if is_raging:
		return

	_rage_decay_timer += delta

	# Начинаем спад только после паузы без событий
	if _rage_decay_timer >= rage_decay_delay:
		rage = max(0.0, rage - rage_decay_rate * delta)
		rage_changed.emit(rage, rage_max)

func add_rage(amount: float):
	if is_raging:
		return
	_rage_decay_timer = 0.0
	rage = min(rage_max, rage + amount * rage_gain_mult)
	rage_changed.emit(rage, rage_max)

	# Звук и сигнал когда шкала заполнена
	if rage >= rage_max:
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.on_rage_ready()

func _activate_rage():
	is_raging = true
	rage = 0.0
	rage_changed.emit(rage, rage_max)

	# Звук активации
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.on_rage_activated()

	# Визуал: красное свечение + пульсация размера
	_start_rage_visuals()

	await get_tree().create_timer(rage_duration).timeout
	
	if hud:
		hud.on_rage_ended()
	
	is_raging = false
	_stop_rage_visuals()

	# Штраф: 1 урон если hp > 1
	if current_hp > 1:
		current_hp -= 1
		health_changed.emit(current_hp, max_hp)

func _start_rage_visuals():
	$Sprite2D.self_modulate = Color(1.0, 0.2, 0.2)

	var tween = create_tween().set_loops()
	tween.tween_property($Sprite2D, "self_modulate", Color(1.0, 0.5, 0.5), 0.4)
	tween.tween_property($Sprite2D, "self_modulate", Color(1.0, 0.1, 0.1), 0.4)
	set_meta("rage_tween", tween)

func _stop_rage_visuals():
	if has_meta("rage_tween"):
		var tween = get_meta("rage_tween")
		if tween and tween.is_valid():
			tween.kill()
		remove_meta("rage_tween")

	$Sprite2D.self_modulate = Color.WHITE
	$Sprite2D.modulate = Color.WHITE     

# ── СТРЕЛЬБА ────────────────────────────────────────────────────

func shoot(direction: Vector2):
	if not projectile_scene: return
	can_shoot = false

	var bullet = projectile_scene.instantiate()
	bullet.set_as_top_level(true)
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position

	var bullet_speed = 520.0
	var side_inertia = 1.1
	var forward_inertia = 0.2

	var forward_v = direction * velocity.dot(direction)
	var side_v = velocity - forward_v
	bullet.velocity = (direction * bullet_speed) + (forward_v * forward_inertia) + (side_v * side_inertia)

	if "damage" in bullet:
		var current_damage = damage * (rage_dmg_mult if is_raging else 1.0)
		bullet.damage = int(current_damage)

	if "max_range" in bullet:
		var range_bonus = Artifacts.get_bullet_flag("range", 0.0)
		bullet.max_range = bullet_range + range_bonus

	if "apply_flags" in bullet:
		bullet.apply_flags()

	var current_shoot_delay = shoot_delay * (rage_shoot_mult if is_raging else 1.0)
	await get_tree().create_timer(current_shoot_delay).timeout
	can_shoot = true

# ── АКТИВНЫЕ СПОСОБНОСТИ ────────────────────────────────────────

func use_active(artifact_id: String):
	var data = Artifacts.get_data(artifact_id)
	if data.is_empty(): return

	var ability = data["effect"]["ability"]
	var cooldown = data["effect"]["cooldown"]

	match ability:
		"dash": _ability_dash()
		"bomb": _ability_bomb()

	can_use_active = false
	active_cooldown_remaining = cooldown
	active_cooldown_updated.emit(active_cooldown_remaining, cooldown)

func _ability_dash():
	var dir = velocity.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT.rotated($Sprite2D.rotation)
	var tween = create_tween()
	tween.tween_property(self, "global_position",
		global_position + dir * 200.0, 0.12)
	is_invincible = true
	await get_tree().create_timer(0.15).timeout
	is_invincible = false

func _ability_bomb():
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage * 3)
	var tween = create_tween()
	tween.tween_property($Sprite2D, "self_modulate", Color.WHITE * 3.0, 0.05)
	tween.tween_property($Sprite2D, "self_modulate", Color.WHITE, 0.2)

# ── УРОН И СМЕРТЬ ────────────────────────────────────────────────

func take_damage(amount: int):
	if is_invincible: return
	current_hp -= amount
	current_hp = max(0, current_hp)
	health_changed.emit(current_hp, max_hp)

	# Урон даёт ярость
	add_rage(rage_dmg_gain)

	if current_hp <= 0:
		die()
	else:
		start_invincibility()

func start_invincibility():
	is_invincible = true
	var tween = create_tween().set_loops(5)
	tween.tween_property($Sprite2D, "modulate:a", 0.5, 0.1)
	tween.tween_property($Sprite2D, "modulate:a", 1.0, 0.1)
	await get_tree().create_timer(invincibility_duration).timeout
	is_invincible = false
	$Sprite2D.modulate.a = 1.0

func handle_restart_input(delta):
	if _restarting:
		return
	if Input.is_action_pressed("restart"):
		_restart_hold_time += delta
		var progress = _restart_hold_time / RESTART_HOLD_DURATION
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.set_restart_overlay(progress)
		if _restart_hold_time >= RESTART_HOLD_DURATION:
			_trigger_restart()
	else:
		if _restart_hold_time > 0.0:
			_restart_hold_time = 0.0
			var hud = get_tree().get_first_node_in_group("hud")
			if hud:
				var tween = create_tween()
				tween.tween_method(hud.set_restart_overlay, hud.restart_overlay.modulate.a, 0.0, 0.3)

func _trigger_restart():
	_restarting = true
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		var tween = create_tween()
		tween.tween_method(hud.set_restart_overlay, hud.restart_overlay.modulate.a, 1.0, 0.4)
		await tween.finished
	Game.restart_game()

func die():
	Game.change_state(Game.GameState.GAME_OVER)
