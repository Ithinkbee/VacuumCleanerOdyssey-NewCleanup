extends Node2D
class_name Room

signal room_change_requested(dir)

var grid_pos: Vector2i
var is_cleared: bool = false
var is_initializing: bool = true 
var hatch_position: Vector2 = Vector2.ZERO #для комнат боссов

func _ready():
	pass

func initialize():
	var data = Game.floor_data.get(grid_pos)
	if data and data["cleared"]:
		is_cleared = true
		set_doors_lock(false)
		if has_node("Spawns"):
			$Spawns.queue_free()
		if data.get("has_hatch", false):
			_restore_hatch()
		if data.get("artifact_id", "") != "":
			_restore_artifact(data["artifact_id"])
		is_initializing = false
	else:
		is_cleared = false
		set_doors_lock(true)
		spawn_content()

func spawn_content():
	is_initializing = true

	if has_node("Spawns"):
		for marker in $Spawns.get_children():
			if marker.is_in_group("spawn_hatch"):
				hatch_position = marker.global_position
				continue

			var path = ""
			if marker.is_in_group("spawn_enemy_walker"): path = "res://scenes/entities/EnemyWalker.tscn"
			elif marker.is_in_group("spawn_enemy_shooter"): path = "res://scenes/entities/EnemyShooter.tscn"
			elif marker.is_in_group("spawn_boss"): path = "res://scenes/entities/Boss.tscn"
			elif marker.is_in_group("spawn_artifact"):
				var art_id = Artifacts.get_random_id()
				if art_id != "":
					var art_scene = load("res://scenes/items/Artifact.tscn")
					if art_scene:
						var art = art_scene.instantiate()
						var local_pos = marker.position
						add_child(art)
						art.position = local_pos
						art.setup(art_id)
						# Сохраняем для восстановления при повторном входе
						Game.mark_room_has_artifact(grid_pos, art_id)
						Game.floor_data[grid_pos]["artifact_local_pos"] = local_pos

			if path != "":
				var scene = load(path)
				if scene:
					var instance = scene.instantiate()
					add_child(instance)
					instance.global_position = marker.global_position

			marker.queue_free()
	else:
		pass

	is_initializing = false
	call_deferred("_check_if_cleared")

func on_enemy_died():
	call_deferred("_check_if_cleared")

func _check_if_cleared():
	if is_cleared or is_initializing:
		return
	for child in get_children():
		if child.is_in_group("enemies") and not child.is_queued_for_deletion():
			return
	clear_room()

func clear_room():
	if is_cleared: return

	is_cleared = true
	set_doors_lock(false)
	Game.mark_room_as_cleared(grid_pos)

	if hatch_position != Vector2.ZERO:
		Game.mark_room_has_hatch(grid_pos)

	spawn_hatch()

func _restore_hatch():
	# При повторном входе в зачищенную комнату восстанавливаем люк
	var pos = Game.floor_data[grid_pos].get("hatch_world_pos", Vector2.ZERO)
	if pos == Vector2.ZERO:
		return
	var hatch_scene = load("res://scenes/levels/Hatch.tscn")
	if hatch_scene:
		var hatch = hatch_scene.instantiate()
		add_child(hatch)
		hatch.global_position = pos

func _restore_artifact(artifact_id: String):
	var art_scene = load("res://scenes/items/Artifact.tscn")
	if art_scene:
		var art = art_scene.instantiate()
		var local_pos = Game.floor_data[grid_pos].get("artifact_local_pos", Vector2.ZERO)
		add_child(art)
		art.position = local_pos
		art.setup(artifact_id)

func set_doors_lock(locked: bool):
	if has_node("Doors"):
		for door in $Doors.get_children():
			door.set_lock(locked)

func request_room_change(dir):
	room_change_requested.emit(dir)

func spawn_hatch():
	if hatch_position == Vector2.ZERO:
		return
	var hatch_scene = load("res://scenes/levels/Hatch.tscn")
	if hatch_scene:
		var hatch = hatch_scene.instantiate()
		add_child(hatch)
		hatch.global_position = hatch_position
		Game.floor_data[grid_pos]["hatch_world_pos"] = hatch_position
