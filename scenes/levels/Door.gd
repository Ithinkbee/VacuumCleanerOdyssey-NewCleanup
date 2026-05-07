extends Area2D

const TEX_CLOSED = preload("res://assets/door_closed.jpg")
const TEX_OPEN   = preload("res://assets/door_open.jpg")

@export var direction: String = "right"
var is_locked: bool = false

func set_lock(locked: bool):
	is_locked = locked
	$Sprite2D.texture = TEX_CLOSED if is_locked else TEX_OPEN

func _on_body_entered(body):
	if is_locked:
		return

	if body.is_in_group("player"):
		Game.request_world_room_change.emit(direction)
