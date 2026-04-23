extends Enemy

func _physics_process(_delta):
	if not player: return
	
	# Вычисляем направление к игроку
	var direction = (player.global_position - global_position).normalized()
	
	velocity = direction * speed
	move_and_slide()
	
	# Проверяем, не коснулись ли мы игрока
	check_player_collision()
