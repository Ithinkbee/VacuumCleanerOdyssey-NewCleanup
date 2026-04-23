extends Area2D

var artifact_id: String = ""
var _bob_time: float = 0.0
var _base_y: float = 0.0

@onready var sprite = $Sprite2D
@onready var beam = $BeamParticles

func _ready():
	body_entered.connect(_on_body_entered)
	$ProximityArea.body_entered.connect(_on_proximity_entered)
	$ProximityArea.body_exited.connect(_on_proximity_exited)

func setup(id: String):
	artifact_id = id
	var data = Artifacts.get_data(id)
	if data.is_empty():
		return

	var col: Color = data.get("color", Color.WHITE)
	if sprite.texture == null:
		var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		img.fill(col)
		sprite.texture = ImageTexture.create_from_image(img)
	else:
		sprite.self_modulate = col

	if beam:
		beam.self_modulate = col

	_base_y = position.y

func _process(delta):
	_bob_time += delta
	position.y = _base_y + sin(_bob_time * 2.0) * 6.0

func _on_proximity_entered(body):
	if body.is_in_group("player"):
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			var data = Artifacts.get_data(artifact_id)
			hud.show_artifact_description(data["name"], data["description"])

func _on_proximity_exited(body):
	if body.is_in_group("player"):
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.hide_artifact_description()

func _on_body_entered(body):
	if body.is_in_group("player"):
		_apply_to_player(body)

func _apply_to_player(player):
	var data = Artifacts.get_data(artifact_id)
	if data.is_empty():
		return

	var type = data["type"]
	var effect = data["effect"]

	match type:
		"stat":
			_apply_stat(player, effect)
		"bullet":
			Artifacts.apply_bullet_flag(effect["flag"], effect["value"])
		"active":
			Artifacts.active_artifact = artifact_id
			# Сообщаем HUD об активном предмете
			var hud = get_tree().get_first_node_in_group("hud")
			if hud:
				hud.set_active_artifact(data)
		"visual":
			_apply_visual(effect)

	Artifacts.collected.append(artifact_id)

	# Показываем название подбора на HUD
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_artifact_pickup(data["name"])
		hud.hide_artifact_description()
	
	var parent = get_parent()
	if parent is Room:
		Game.floor_data[parent.grid_pos]["artifact_id"] = ""
	
	queue_free()

func _apply_stat(player, effect: Dictionary):
	match effect["stat"]:
		"speed":
			player.speed += effect["value"]
		"max_hp":
			player.max_hp += int(effect["value"])
			player.current_hp += int(effect["value"])
			player.health_changed.emit(player.current_hp, player.max_hp)
		"damage":
			player.damage += int(effect["value"])
		"shoot_delay":
			player.shoot_delay = max(0.05, player.shoot_delay + effect["value"])

func _apply_visual(effect: Dictionary):
	match effect["visual"]:
		"slow_time":
			# Engine.time_scale замедляет весь мир, но не UI
			Engine.time_scale = effect["value"]
