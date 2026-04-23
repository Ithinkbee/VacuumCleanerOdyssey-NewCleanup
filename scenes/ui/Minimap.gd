extends Control

const CELL_SIZE = Vector2(18, 12)
const CELL_GAP = 2

const COLOR_CURRENT     = Color(1.0, 1.0, 1.0)
const COLOR_VISITED     = Color(0.55, 0.55, 0.65)
const COLOR_ADJACENT    = Color(0.35, 0.35, 0.42) 
const COLOR_BOSS        = Color(0.85, 0.2, 0.2)
const COLOR_BOSS_ADJ    = Color(0.5, 0.12, 0.12)  
const COLOR_TREASURE    = Color(0.95, 0.85, 0.2)
const COLOR_TREASURE_ADJ = Color(0.55, 0.5, 0.12)  
const COLOR_START       = Color(0.3, 0.8, 0.4)
const COLOR_BORDER      = Color(0.08, 0.08, 0.1)

func _draw():
	if Game.floor_data.is_empty():
		return

	var positions = Game.floor_data.keys()
	var min_x = positions[0].x
	var max_x = positions[0].x
	var min_y = positions[0].y
	var max_y = positions[0].y

	for pos in positions:
		min_x = min(min_x, pos.x)
		max_x = max(max_x, pos.x)
		min_y = min(min_y, pos.y)
		max_y = max(max_y, pos.y)

	var map_pixel_size = Vector2(
		(max_x - min_x + 1) * (CELL_SIZE.x + CELL_GAP),
		(max_y - min_y + 1) * (CELL_SIZE.y + CELL_GAP)
	)
	var draw_offset = (size - map_pixel_size) / 2.0

	for pos in positions:
		var data = Game.floor_data[pos]
		var is_current = (pos == _get_current_pos())
		var is_visited = Game.visited_rooms.has(pos)
		var is_adjacent = _is_adjacent_to_visited(pos)

		# Скрываем комнаты, о которых игрок ничего не знает
		if not is_current and not is_visited and not is_adjacent:
			continue

		var cell_pos = Vector2(
			(pos.x - min_x) * (CELL_SIZE.x + CELL_GAP),
			(pos.y - min_y) * (CELL_SIZE.y + CELL_GAP)
		) + draw_offset

		var rect = Rect2(cell_pos, CELL_SIZE)
		var type = data.get("type", "normal")

		var col: Color
		if is_current:
			col = COLOR_CURRENT
		elif is_visited:
			# Посещённые — полный цвет по типу
			match type:
				"boss":     col = COLOR_BOSS
				"treasure": col = COLOR_TREASURE
				"start":    col = COLOR_START
				_:          col = COLOR_VISITED
		else:
			# Соседние непосещённые — тусклый цвет по типу
			match type:
				"boss":     col = COLOR_BOSS_ADJ
				"treasure": col = COLOR_TREASURE_ADJ
				_:          col = COLOR_ADJACENT

		draw_rect(rect.grow(1), COLOR_BORDER)
		draw_rect(rect, col)

		if is_current:
			var center = cell_pos + CELL_SIZE / 2.0
			draw_circle(center, 3.0, Color(0.2, 0.2, 0.2))

		# Коридоры рисуем если хотя бы одна из двух комнат посещена/текущая
		_draw_corridors(pos, cell_pos, is_visited or is_current)

func _is_adjacent_to_visited(pos: Vector2i) -> bool:
	# Комната считается видимой если рядом есть посещённая
	for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if Game.visited_rooms.has(pos + dir):
			return true
	return false

func _draw_corridors(pos: Vector2i, cell_pos: Vector2, visible_enough: bool):
	if not visible_enough:
		return

	var neighbors = {
		Vector2i.RIGHT: Vector2(CELL_SIZE.x, CELL_SIZE.y / 2.0 - 1),
		Vector2i.DOWN:  Vector2(CELL_SIZE.x / 2.0 - 1, CELL_SIZE.y)
	}

	for dir in neighbors:
		var neighbor = pos + dir
		if Game.floor_data.has(neighbor):
			var corridor_pos = cell_pos + neighbors[dir]
			var corridor_size = Vector2(
				CELL_GAP if dir == Vector2i.RIGHT else 2,
				2 if dir == Vector2i.RIGHT else CELL_GAP
			)
			draw_rect(Rect2(corridor_pos, corridor_size), COLOR_ADJACENT)

func _get_current_pos() -> Vector2i:
	var world = get_tree().get_first_node_in_group("world")
	if world:
		return world.current_grid_pos
	return Vector2i(0, 0)
