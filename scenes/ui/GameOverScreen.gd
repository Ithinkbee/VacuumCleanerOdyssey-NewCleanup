extends CanvasLayer

func _on_restart_button_pressed():
	Game.restart_game()

func _on_quit_button_pressed():
	Game.quit_to_menu()
