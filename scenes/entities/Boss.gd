extends Enemy

@export var size: int = 3 
var bounce_velocity = Vector2.ZERO
var rotation_speed = 0.0

func _ready():
	# Важно: добавляем в группу именно "bosses", чтобы легче было считать живых боссов
	add_to_group("bosses")
	super._ready()
	
	# Вызываем настройку статов здесь
	setup_boss_stats()
	
	bounce_velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * speed
	rotation_speed = randf_range(1.0, 3.0)

func setup_boss_stats():
	# Убедимся, что спрайт существует перед настройкой
	if not has_node("Sprite2D"): return
	
	match size:
		3:
			hp = 20
			speed = 150.0
			scale = Vector2(2.5, 2.5)
		2:
			hp = 10
			speed = 220.0
			scale = Vector2(1.5, 1.5)
		1:
			hp = 5
			speed = 300.0
			scale = Vector2(0.8, 0.8)

func _physics_process(delta):
	if Game.current_state != Game.GameState.PLAYING: return
	
	if has_node("Sprite2D"):
		$Sprite2D.rotation += rotation_speed * delta
	
	velocity = bounce_velocity
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		var collider = collision.get_collider()
		if collider.is_in_group("player"):
			collider.take_damage(damage)
		
		bounce_velocity = bounce_velocity.bounce(collision.get_normal())
		bounce_velocity *= randf_range(0.95, 1.05)

func die():
	if size > 1:
		# Используем call_deferred для безопасного спавна детей
		call_deferred("spawn_children")
	else:
		call_deferred("check_victory_condition")
	
	# Убираем его из группы сразу, чтобы счетчик не ошибался
	remove_from_group("bosses")
	queue_free()

func spawn_children():
	var child_count = 2 if size == 3 else 3
	var boss_scene = load("res://scenes/entities/Boss.tscn")
	
	for i in range(child_count):
		var child = boss_scene.instantiate()
		child.size = size - 1
		
		# Добавляем ребенка в комнату (родитель текущего босса)
		get_parent().add_child(child)
		
		# Задаем позицию после добавления в дерево
		child.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))

func check_victory_condition():
	# Даем время на удаление объектов
	await get_tree().process_frame
	
	# Считаем только боссов
	var bosses = get_tree().get_nodes_in_group("bosses")
	if bosses.size() == 0:
		spawn_trophy()

func spawn_trophy():
	var trophy_path = "res://scenes/items/Trophy.tscn" 
	if ResourceLoader.exists(trophy_path):
		var trophy_scene = load(trophy_path)
		var trophy = trophy_scene.instantiate()
		get_parent().add_child(trophy)
		trophy.global_position = global_position
		print("Трофей появился!")
	else:
		print("Ошибка: Файл трофея не найден по пути: ", trophy_path)
