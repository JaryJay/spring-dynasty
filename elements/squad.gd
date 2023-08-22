@tool
extends CharacterBody2D
class_name Squad

@export var unit_scene: PackedScene : set = _set_unit_scene

## The number of units in the squad
@export var size: int = 10 : set = _set_size

var units: Array[Unit] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _set_unit_scene(scene: PackedScene) -> void:
	if not unit_scene == scene:
		for unit in units:
			unit.queue_free()
		units.clear()
		if scene:
			for i in range(size):
				var unit: = scene.instantiate()
				add_child(unit, false, Node.INTERNAL_MODE_FRONT)
				unit.position = Vector2.UP.rotated(i * PI / 3) * i * 5
				units.append(unit)
	unit_scene = scene

func _set_size(s: int) -> void:
	size = s
	print_debug("Hi")
