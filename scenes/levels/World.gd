extends Node2D

@onready var generator = $FloorGenerator
@onready var room_container = $RoomContainer
@onready var player = $Player
@onready var camera = $Camera2D

var floor_plan = {}
var current_grid_pos = Vector2i(0, 0)
var room_size = Vector2(1152, 648) 
var is_changing_room = false

func _ready():
	# Генерируем карту
	floor_plan = generator.generate_floor()
	Game.floor_data = floor_plan
	
	Game.request_world_room_change.connect(_on_room_change_requested)
	
	load_room(Vector2i(0,0))
	
	$Player.health_changed.connect($HUD.update_health)
	$Player.active_cooldown_updated.connect($HUD.update_active_cooldown)
	$Player.rage_changed.connect($HUD.update_rage)
	
	# Инициализируем HUD первым значением
	$HUD.update_health($Player.current_hp, $Player.max_hp)
	
	var hud = $HUD
	if hud and hud.has_method("set_restart_overlay"):
		hud.set_restart_overlay(1.0)
		var tween = create_tween()
		tween.tween_method(hud.set_restart_overlay, 1.0, 0.0, 0.8)

func load_room(grid_pos):
	for child in room_container.get_children():
		child.queue_free()

	var room_path = floor_plan[grid_pos]["scene"]
	var room_instance = load(room_path).instantiate()

	room_instance.grid_pos = grid_pos
	room_instance.room_change_requested.connect(_on_room_change_requested)

	room_container.add_child(room_instance)

	var world_pos = Vector2(grid_pos.x * room_size.x, grid_pos.y * room_size.y)
	room_instance.global_position = world_pos

	camera.global_position = world_pos + (room_size / 2)
	_setup_room_doors(room_instance, grid_pos)

	# Ждём один физический кадр — позиция гарантированно применится
	await get_tree().physics_frame

	room_instance.initialize()

	Game.mark_room_visited(grid_pos)
	if has_node("HUD"):
		$HUD.update_minimap()

func _setup_room_doors(room, pos):
	# Проверяем соседей в 4 направлениях
	var neighbors = {
		"up": floor_plan.has(pos + Vector2i.UP),
		"down": floor_plan.has(pos + Vector2i.DOWN),
		"left": floor_plan.has(pos + Vector2i.LEFT),
		"right": floor_plan.has(pos + Vector2i.RIGHT)
	}
	
	# Ищем в комнате узел Doors и скрываем те двери, где нет соседа
	if room.has_node("Doors"):
		for door in room.get_node("Doors").get_children():
			# Если в этом направлении нет комнаты — удаляем или скрываем дверь
			if not neighbors.get(door.direction, false):
				door.queue_free() # Или door.visible = false

func _on_room_change_requested(dir):
	if is_changing_room: 
		return
	
	var next_pos = current_grid_pos
	match dir:
		"up": next_pos += Vector2i.UP
		"down": next_pos += Vector2i.DOWN
		"left": next_pos += Vector2i.LEFT
		"right": next_pos += Vector2i.RIGHT
	
	if floor_plan.has(next_pos):
		is_changing_room = true
		current_grid_pos = next_pos
		call_deferred("load_room", current_grid_pos)
		call_deferred("_move_player_to_opposite_door", dir)
		
		await get_tree().create_timer(0.2).timeout
		is_changing_room = false
	else:
		pass

func _move_player_to_opposite_door(dir):
	var center = Vector2(current_grid_pos.x * room_size.x, current_grid_pos.y * room_size.y) + (room_size / 2)
	var offset_x = room_size.x / 2 - 160 
	var offset_y = room_size.y / 2 - 140
	
	match dir:
		"right": player.global_position = center - Vector2(offset_x, 0)
		"left": player.global_position = center + Vector2(offset_x, 0)
		"up": player.global_position = center + Vector2(0, offset_y)
		"down": player.global_position = center - Vector2(0, offset_y)
	
	player.velocity = Vector2.ZERO
