class_name World extends Node2D

const city_scene: = preload("res://worlds/city.tscn")
@export var world_map: Node2D
@onready var camera: = $Camera
@onready var pause_menu: = $PauseMenuLayer/PauseMenu

var data: WorldData

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		pause_menu.visible = !pause_menu.visible
	camera.disable_pan = pause_menu.visible

func create() -> void:
	var city_markers: Array[Node] = $WorldMap1/CapitalCities.get_children()
	city_markers.shuffle()
	for i: int in range(15):
		var team: = i + 1
		var city: City = city_scene.instantiate()
		city.name = "City%d" % team
		add_child(city)
		city.set_team(team)
		city.position = city_markers[i].position
	
	data = WorldData.new()
	data.player_team = 11
	
	var starting_city: City = get_node("City%d" % data.player_team)
	camera.position = starting_city.position
	data.camera_position = camera.position
	data.camera_zoom = camera.target_zoom

func save() -> void:
	data.camera_position = camera.position
	data.camera_zoom = camera.zoom
	ResourceSaver.save(data, "user://world_data.tres")
	
	var save_file: = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	if FileAccess.get_open_error():
		print("Save failed. Error: %s" % error_string(FileAccess.get_open_error()))
		return
	
	# Save cities
	for city: Node in get_children():
		if not city is City:
			continue
		print("Storing line '%s'" % JSON.stringify({ "position": city.position, "team": city.team }))
		save_file.store_line(JSON.stringify({ "position": city.position, "team": city.team }))
		# TODO
		pass
	save_file.close()

func load(save_path: String = "user://savegame.save") -> void:
	data = ResourceLoader.load("user://world_data.tres")
	camera.set_position.call_deferred(data.camera_position)
	camera.set_zoom.call_deferred(data.camera_zoom)
	# Code copied from:
	# https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html#saving-and-reading-data
	var file: = FileAccess.open(save_path, FileAccess.READ)
	while file.get_position() < file.get_length():
		var json_string: = file.get_line()

		# Creates the helper class to interact with JSON
		var json: = JSON.new()

		# Check if there is any error while parsing the JSON string, skip in case of failure
		var error: = json.parse(json_string)
		if error:
			push_error("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		# Get the data from the JSON object
		var node_data: Variant = json.get_data()
		
		if not ("position" in node_data and "team" in node_data):
			push_error("Load Game Error: %s" % node_data)
		# Firstly, we need to create the object and add it to the tree and set its position.
		var city: Node2D = load("res://worlds/city.tscn").instantiate()
		add_child.call_deferred(city)
		city.position = parse_vector2(node_data.position)
		city.team = node_data.team
	file.close()

func _on_pause_menu_exit_pressed():
	queue_free()
	save()
func _on_pause_menu_quit_pressed():
	save()

func parse_vector2(str: String) -> Vector2:
	var x: = int(str.split(", ")[0].lstrip("("))
	var y: = int(str.split(", ")[1].rstrip(")"))
	return Vector2(x, y)
