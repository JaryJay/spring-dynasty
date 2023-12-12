extends Camera2D

@export_range(0, 800) var pan_speed: float
@export var follow_mode_enabled: bool

var disable_pan: = false

var pan_velocity: Vector2 = Vector2.ZERO
var target_zoom: Vector2 = Vector2.ONE
var follow_targets: Array

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
	if target_zoom.length_squared() / 2 < 0.4 * 0.4:
		target_zoom = Vector2(0.4, 0.4)
	elif target_zoom.length_squared() / 2 > 2.0 * 2.0:
		target_zoom = Vector2(2.0, 2.0)

func _remove_invalid_follow_targets() -> void:
	for i in range(follow_targets.size() - 1, -1, -1):
		if not is_instance_valid(follow_targets[i]):
			follow_targets.remove_at(i)
