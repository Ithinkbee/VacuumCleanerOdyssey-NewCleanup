extends Node

@export var min_rooms: int = 6
@export var max_rooms: int = 10

var start_room_scene = "res://scenes/levels/rooms/special/StartRoom.tscn"
var normal_room_scenes = [
	"res://scenes/levels/rooms/normal/Room1.tscn",
	"res://scenes/levels/rooms/normal/Room2.tscn",
	"res://scenes/levels/rooms/normal/Room3.tscn"
]
var boss_room_scene = "res://scenes/levels/rooms/special/BossRoom.tscn"
var treasure_room_scene = "res://scenes/levels/rooms/special/TreasureRoom.tscn"

var floor_plan = {}

func generate_floor():
	floor_plan.clear()

	var temp_grid = { Vector2i(0, 0): "start" }
	var rooms_to_create = randi_range(min_rooms, max_rooms)
	var queue = [Vector2i(0, 0)]

	while temp_grid.size() < rooms_to_create:
		var current_pos = queue.pick_random()
		var dir = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT].pick_random()
		var new_pos = current_pos + dir

		if not temp_grid.has(new_pos) and count_neighbors_in_grid(temp_grid, new_pos) <= 1:
			temp_grid[new_pos] = "normal"
			queue.append(new_pos)

	# Босс — самая далёкая от старта комната
	var boss_pos = find_furthest_room_in_grid(temp_grid, Vector2i(0, 0))
	temp_grid[boss_pos] = "boss"

	# Собираем нормальные комнаты, кандидаты на сокровищницу:
	# - не старт, не босс
	# - не соседствуют со стартом (чтобы не было слишком близко)
	var treasure_candidates = []
	for pos in temp_grid:
		if temp_grid[pos] != "normal":
			continue
		if count_specific_neighbor(temp_grid, pos, "start") > 0:
			continue
		treasure_candidates.append(pos)

	# Если кандидатов нет — берём любую нормальную
	if treasure_candidates.is_empty():
		for pos in temp_grid:
			if temp_grid[pos] == "normal":
				treasure_candidates.append(pos)

	# Всегда 1 сокровищница, с шансом 15% — вторая
	var treasure_count = 1
	if randf() < 0.15:
		treasure_count = 2

	treasure_candidates.shuffle()
	for i in range(min(treasure_count, treasure_candidates.size())):
		temp_grid[treasure_candidates[i]] = "treasure"

	# Собираем финальный floor_plan
	for pos in temp_grid:
		var type = temp_grid[pos]
		floor_plan[pos] = {
			"scene": _pick_scene_for_type(type),
			"cleared": (type == "start"),
			"has_hatch": false,
			"hatch_world_pos": Vector2.ZERO,
			"type": type
		}

	return floor_plan

func _pick_scene_for_type(type: String) -> String:
	match type:
		"start":    return start_room_scene
		"boss":     return boss_room_scene
		"treasure": return treasure_room_scene
		_:          return normal_room_scenes.pick_random()

func count_neighbors_in_grid(grid: Dictionary, pos: Vector2i) -> int:
	var count = 0
	for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if grid.has(pos + d):
			count += 1
	return count

func count_specific_neighbor(grid: Dictionary, pos: Vector2i, type: String) -> int:
	var count = 0
	for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var neighbor = pos + d
		if grid.has(neighbor) and grid[neighbor] == type:
			count += 1
	return count

func find_furthest_room_in_grid(grid: Dictionary, start_pos: Vector2i) -> Vector2i:
	var furthest = start_pos
	var max_d = 0
	for p in grid:
		var d = abs(p.x) + abs(p.y)
		if d > max_d:
			max_d = d
			furthest = p
	return furthest
