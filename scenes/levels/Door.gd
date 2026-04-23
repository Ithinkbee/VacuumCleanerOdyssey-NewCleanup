extends Area2D

@export var direction: String = "right"
var is_locked: bool = false

func set_lock(locked: bool):
	is_locked = locked
	var sprite = $Sprite2D
	
	if is_locked:
		sprite.texture = load("res://assets/door_closed.jpg")
		print("Дверь заперта: ", direction)
	else:
		sprite.texture = load("res://assets/door_open.jpg")
		print("Дверь открыта: ", direction)

func _on_body_entered(body):
	print("ДВЕРЬ КОСНУЛСЯ ОБЪЕКТ: ", body.name)
	
	if is_locked: 
		print("Но дверь заперта!")
		return 
	
	if body.is_in_group("player"):
		print("Это игрок! Шлю сигнал перехода...")
		Game.request_world_room_change.emit(direction)
	else:
		print("Это не игрок, это: ", body.get_groups())
