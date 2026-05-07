extends CharacterBody2D
class_name Enemy

@export var hp: int = 3
@export var speed: float = 100.0
@export var damage: int = 1

var player: CharacterBody2D = null

func _ready():
	# Ищем игрока в группе "player"
	player = get_tree().get_first_node_in_group("player")
	add_to_group("enemies")

func take_damage(amount: int):
	hp -= amount
	
	if has_node("Sprite2D"):
		var tween = create_tween()
		tween.tween_property($Sprite2D, "self_modulate", Color.RED, 0.1)
		tween.tween_property($Sprite2D, "self_modulate", Color.WHITE, 0.1)
	
	if hp <= 0:
		die()

func die():
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_rage"):
		player.add_rage(player.rage_kill_gain)

	var parent = get_parent()
	if parent and parent.has_method("on_enemy_died"):
		parent.on_enemy_died()

	queue_free()

func check_player_collision():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("player"):
			collider.take_damage(damage)
