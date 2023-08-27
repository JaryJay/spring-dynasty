extends VBoxContainer

@export var game_scene: PackedScene
@export var settings_menu: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_play_button_pressed():
	get_tree().change_scene_to_packed(game_scene)


func _on_settings_button_pressed():
	var settingsMenuInstance = settings_menu.instantiate()
	get_tree().root.get_node("MainMenu").add_child(settingsMenuInstance)


func _on_quit_button_pressed():
	get_tree().quit()
