extends VBoxContainer

@export var sceneToLoad: PackedScene
@export var settingsMenu: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_play_button_pressed():
	get_tree().change_scene_to_packed(sceneToLoad)


func _on_settings_button_pressed():
	var settingsMenuInstance = settingsMenu.instantiate()
	get_tree().root.get_node("MainMenu").add_child(settingsMenuInstance)


func _on_quit_button_pressed():
	get_tree().quit()
