extends Control

@export var game_scene: PackedScene
@export var settings_menu: PackedScene

func _on_play_button_pressed():
	get_tree().change_scene_to_packed(game_scene)

func _on_settings_button_pressed():
	var settingsMenuInstance = settings_menu.instantiate()
	add_child(settingsMenuInstance)

func _on_quit_button_pressed():
	get_tree().quit()
