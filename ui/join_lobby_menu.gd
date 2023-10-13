extends Control

const lobby_menu_scene: PackedScene = preload("res://ui/lobby_menu.tscn")

@onready var error_label: = %ErrorLabel



func _enter_lobby():
	var username: String = %NameInput.text
	var server_ip: String = %ServerIPInput.text
	var port: String = %PortInput.text
	
	if username == "" or server_ip == "" or port == "":
		error_label.text = "One or more inputs are empty"
		return
	elif not port.is_valid_int():
		error_label.text = "Invalid port"
		return
	
	Client.user_info["name"] = username
	var result: = Client.init(server_ip, int(port))
	if result != OK:
		error_label.text = "Error %s occurred" % result
	else:
		get_tree().change_scene_to_packed(lobby_menu_scene)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func _on_name_input_text_submitted(_new_text: String):
	_enter_lobby()
