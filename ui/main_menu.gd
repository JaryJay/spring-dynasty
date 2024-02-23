extends Control

@export var join_lobby_menu_scene: PackedScene
@export var settings_menu: PackedScene

func _ready() -> void:
	if "--server" in OS.get_cmdline_user_args():
		queue_free()
		return
	
	modulate = Color.BLACK
	create_tween().tween_property(self, "modulate", Color.WHITE, .5).set_trans(Tween.TRANS_CUBIC)
	# Dev only
	#_on_multiplayer_button_pressed.call_deferred()
	
	check_saved_game()
	
	Client.init_steam()
	var number_of_friends: int = Steam.getFriendCount(Steam.FRIEND_FLAG_IMMEDIATE)
	print("You have %d friends online." % number_of_friends)

func _on_new_game_button_pressed():
	var loading_screen_scene: = load("res://ui/game_loading_screen.tscn")
	var screen: Node = loading_screen_scene.instantiate()
	screen.load_type = GameLoadingScreen.LoadType.CREATE_NEW_GAME
	get_tree().root.add_child(screen)
	queue_free()

func _on_continue_button_pressed():
	var loading_screen_scene: = load("res://ui/game_loading_screen.tscn")
	var screen: Node = loading_screen_scene.instantiate()
	screen.load_type = GameLoadingScreen.LoadType.LOAD_GAME
	get_tree().root.add_child(screen)
	queue_free()

func _on_singleplayer_button_pressed():
	get_tree().change_scene_to_file("res://ui/level_selection_menu.tscn")

func _on_multiplayer_button_pressed():
	get_tree().change_scene_to_packed(join_lobby_menu_scene)

func _on_settings_button_pressed():
	var settingsMenuInstance = settings_menu.instantiate()
	add_child(settingsMenuInstance)

func _on_quit_button_pressed():
	get_tree().quit()

func check_saved_game() -> void:
	if FileAccess.file_exists("user://savegame.save"):
		%NewGameButton.hide()
		%ContinueButton.show()
