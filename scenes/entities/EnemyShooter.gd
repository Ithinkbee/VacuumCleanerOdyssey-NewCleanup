extends Enemy

@export var projectile_scene: PackedScene = preload("res://scenes/projectiles/Projectile.tscn")

func _ready():
	super._ready() # Вызываем ready из базового класса Enemy
	$ShootTimer.timeout.connect(_on_shoot_timer_timeout)

func _physics_process(_delta):
	if not player: return
	
	# Стреляющий враг может медленно пятиться или стоять на месте
	# Давай сделаем, чтобы он держал дистанцию 300 пикселей
	var dist = global_position.distance_to(player.global_position)
	var dir = (player.global_position - global_position).normalized()
	
	if dist > 350:
		velocity = dir * speed
	elif dist < 250:
		velocity = -dir * speed
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()
	check_player_collision()

func _on_shoot_timer_timeout():
	if not player: return
	shoot()

func shoot():
	var bullet = projectile_scene.instantiate()
	# Важно: пуля врага должна быть в другой группе или иметь флаг
	bullet.add_to_group("enemy_projectile") 
	bullet.set_as_top_level(true)
	get_tree().current_scene.add_child(bullet)
	
	bullet.global_position = global_position
	var dir = (player.global_position - global_position).normalized()
	bullet.velocity = dir * 300.0 # Скорость пули врага
