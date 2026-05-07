extends Node

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER, VICTORY }

var current_state = GameState.MENU
var score = 0
var start_time = 0
var final_time = ""

var floor_data = {}
var visited_rooms: Array[Vector2i] = []

signal request_world_room_change(direction)
signal state_changed(new_state)
signal game_ended(win, time)

func mark_room_as_cleared(pos: Vector2i):
	if floor_data.has(pos):
		floor_data[pos]["cleared"] = true

func mark_room_has_hatch(pos: Vector2i):
	if floor_data.has(pos):
		floor_data[pos]["has_hatch"] = true

func mark_room_has_artifact(pos: Vector2i, artifact_id: String):
	if floor_data.has(pos):
		floor_data[pos]["artifact_id"] = artifact_id

func mark_room_visited(pos: Vector2i):
	if not visited_rooms.has(pos):
		visited_rooms.append(pos)

func change_state(new_state: GameState):
	current_state = new_state

	if new_state == GameState.PLAYING:
		floor_data = {}
		visited_rooms = []
		score = 0
		start_time = Time.get_ticks_msec()
		Artifacts.reset()
		Engine.time_scale = 1.0

	if new_state == GameState.VICTORY:
		var raw_time = (Time.get_ticks_msec() - start_time) / 1000.0
		var minutes = int(raw_time / 60)
		var seconds = int(raw_time) % 60
		final_time = "%02d:%02d" % [minutes, seconds]

	match current_state:
		GameState.PLAYING:
			get_tree().call_deferred("change_scene_to_file", "res://scenes/levels/World.tscn")
		GameState.GAME_OVER:
			get_tree().call_deferred("change_scene_to_file", "res://scenes/ui/GameOverScreen.tscn")
		GameState.VICTORY:
			get_tree().call_deferred("change_scene_to_file", "res://scenes/ui/VictoryScreen.tscn")
		GameState.MENU:
			get_tree().call_deferred("change_scene_to_file", "res://scenes/ui/MainMenu.tscn")

func restart_game():
	change_state(GameState.PLAYING)

func quit_to_menu():
	change_state(GameState.MENU)
