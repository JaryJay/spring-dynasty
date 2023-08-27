extends Control

@export var game: Game

# Called when the node enters the scene tree for the first time.
func _ready():
	hide()
	game.connect("client_pause_state_changed", _on_game_client_pause_state_changed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_game_client_pause_state_changed(client_is_paused: bool):
	if client_is_paused:
		show()
	else:
		hide()


func _on_resume_pressed():
	game.client_pause_state = false


func _on_exit_pressed():
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")


func _on_quit_pressed():
	get_tree().quit()
