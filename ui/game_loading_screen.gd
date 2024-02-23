class_name GameLoadingScreen extends CanvasLayer

const WORLD_SCENE_PATH: = "res://world.tscn"
const GAME_SAVE_PATH: = "user://savegame.save"

var load_type: LoadType = LoadType.CREATE_NEW_GAME

enum LoadType {
	CREATE_NEW_GAME,
	LOAD_GAME
}

var world: Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	ResourceLoader.load_threaded_request(WORLD_SCENE_PATH)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var sword: Sprite2D = %Sword
	sword.rotate(delta * 3.0)
	
	if ResourceLoader.load_threaded_get_status(WORLD_SCENE_PATH) != ResourceLoader.THREAD_LOAD_LOADED:
		return
	var world_scene: PackedScene = ResourceLoader.load_threaded_get(WORLD_SCENE_PATH)
	world = world_scene.instantiate()
	
	if load_type == LoadType.LOAD_GAME:
		var thread: = Thread.new()
		thread.start(load_game)
	else:
		get_tree().root.add_child(world)
		world.create_starting_cities()
		transition_to_world.call_deferred()

func transition_to_world() -> void:
	var tw: = create_tween()
	tw.tween_property($ColorRect, "modulate", Color.TRANSPARENT, .2)
	tw.tween_callback(queue_free)

func load_game() -> void:
	# Code copied from:
	# https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html#saving-and-reading-data
	var file: = FileAccess.open(GAME_SAVE_PATH, FileAccess.READ)
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
		var city: Node2D = load("res://world_maps/city.tscn").instantiate()
		world.add_child(city)
		city.position = parse_vector2(node_data.position)
		city.team = node_data.team
	get_tree().root.add_child.call_deferred(world)
	transition_to_world.call_deferred()

func parse_vector2(str: String) -> Vector2:
	var x: = int(str.split(", ")[0].lstrip("("))
	var y: = int(str.split(", ")[1].rstrip(")"))
	return Vector2(x, y)
