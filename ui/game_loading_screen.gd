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
		get_tree().root.add_child(world)
		var thread: = Thread.new()
		thread.start(world.load)
		await thread.wait_to_finish()
		transition_to_world()
	else:
		get_tree().root.add_child(world)
		world.create_starting_cities()
		transition_to_world.call_deferred()

func transition_to_world() -> void:
	var tw: = create_tween()
	tw.tween_property($ColorRect, "modulate", Color.TRANSPARENT, .2)
	tw.tween_callback(queue_free)

func parse_vector2(str: String) -> Vector2:
	var x: = int(str.split(", ")[0].lstrip("("))
	var y: = int(str.split(", ")[1].rstrip(")"))
	return Vector2(x, y)
