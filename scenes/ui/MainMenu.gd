extends CanvasLayer

func _on_start_button_pressed():
	Game.change_state(Game.GameState.PLAYING)

func _on_quit_button_pressed():
	get_tree().quit()
