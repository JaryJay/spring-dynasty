extends Camera2D

@export_range(0, 1600) var pan_speed: float
@export var follow_mode_enabled: bool

@export_range(.01, 1000) var zoom_min: float
@export_range(.01, 1000) var zoom_max: float
@export_range(.01, 100) var initial_zoom: float

var disable_pan: = false

var pan_velocity: Vector2 = Vector2.ZERO
var target_zoom: Vector2 = Vector2.ONE
var follow_targets: Array

func _ready() -> void:
	target_zoom = Vector2.ONE * initial_zoom
	zoom = target_zoom

func _process(delta: float):
	zoom = zoom.lerp(target_zoom, 0.3)
	_update_position(delta)

func _update_position(delta: float) -> void:
	var input_vector: = Input.get_vector("pan_left", "pan_right", "pan_up", "pan_down")
	_remove_invalid_follow_targets()
	if follow_mode_enabled and not follow_targets.is_empty():
		var target_position_sum = Vector2.ZERO
		for node: Node2D in follow_targets:
			target_position_sum += node.global_position
		position = target_position_sum / follow_targets.size()
		if disable_pan:
			return
		position += input_vector * pan_speed * 0.5
	else:
		if disable_pan:
			return
		pan_velocity = input_vector * pan_speed * delta
		position += pan_velocity

func _unhandled_input(_event):
	if Input.is_action_just_pressed("zoom_in"):
		target_zoom *= 1 / 0.93
	if Input.is_action_just_pressed("zoom_out"):
		target_zoom *= 0.93
	
	# Clamp target_zoom
	target_zoom = target_zoom.clamp(Vector2(zoom_min, zoom_min), Vector2(zoom_max, zoom_max))

func _remove_invalid_follow_targets() -> void:
	for i in range(follow_targets.size() - 1, -1, -1):
		if not is_instance_valid(follow_targets[i]):
			follow_targets.remove_at(i)
