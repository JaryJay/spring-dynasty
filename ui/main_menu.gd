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

func _on_singleplayer_button_pressed():
	get_tree().change_scene_to_file("res://ui/level_selection_menu.tscn")

func _on_multiplayer_button_pressed():
	get_tree().change_scene_to_packed(join_lobby_menu_scene)

func _on_settings_button_pressed():
	var settingsMenuInstance = settings_menu.instantiate()
	add_child(settingsMenuInstance)

func _on_quit_button_pressed():
	get_tree().quit()

