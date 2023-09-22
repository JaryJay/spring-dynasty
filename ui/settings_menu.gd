extends Control

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")


func _on_quit_button_pressed():
	get_tree().quit()
