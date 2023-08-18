extends Node

# Autoload as User

func _ready():
	pass

# Note: this function will not work until steam_appid.txt has a valid app id
func init_steam() -> void:
	var init: Dictionary = Steam.steamInit()
	print("user.gd: Initializing steam...")
	print(init)
	
	if init.status != 1:
		print("user.gd: Failed to initialize Steam. Error message:")
		print(init.verbal)
		print("Shutting down...")
		get_tree().quit()
