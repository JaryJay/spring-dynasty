class_name World extends Node2D

const city_scene: = preload("res://world_maps/city.tscn")
@export var world_map: Node2D
@onready var camera: = $Camera
@onready var pause_menu: = $PauseMenuLayer/PauseMenu

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		pause_menu.visible = !pause_menu.visible
	camera.disable_pan = pause_menu.visible

func create_starting_cities() -> void:
	var city_markers: Array[Node] = $WorldMap1/CapitalCities.get_children()
	city_markers.shuffle()
	for i: int in range(15):
		var team: = i + 1
		var city: City = city_scene.instantiate()
		add_child(city)
		city.set_team(team)
		city.position = city_markers[i].position

func save() -> void:
	var save_file: = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	if FileAccess.get_open_error():
		print("Save failed. Error: %s" % error_string(FileAccess.get_open_error()))
		return
	for city: Node in get_children():
		if not city is City:
			continue
		print("Storing line '%s'" % JSON.stringify({ "position": city.position, "team": city.team }))
		save_file.store_line(JSON.stringify({ "position": city.position, "team": city.team }))
		# TODO
		pass
	save_file.close()

func _on_pause_menu_exit_pressed():
	queue_free()
	save()
func _on_pause_menu_quit_pressed():
	save()
