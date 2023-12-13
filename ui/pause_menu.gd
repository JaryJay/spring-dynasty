extends Control

func _on_feedback_pressed():
	OS.shell_open("https://forms.gle/zc3xBB2fTRfZW8kq9")

func _on_exit_pressed():
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func _on_quit_pressed():
	get_tree().quit()
