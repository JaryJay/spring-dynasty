extends Camera2D

@export_range(0, 500) var pan_speed: = 30.0

var disable_pan: = false

var pan_mouse_start_position: = Vector2.ZERO
var pan_velocity: Vector2 = Vector2.ZERO
var target_zoom: Vector2 = Vector2.ONE

func _process(delta):
	if not disable_pan:
		if Input.is_action_pressed("pan_camera"):
			var mouse_pos: = get_local_mouse_position()
			var pan_direction: = (mouse_pos - pan_mouse_start_position) * 0.5
			pan_direction = pan_direction.normalized() * clampf(pan_direction.length(), 0, 20)
			pan_velocity = pan_direction * pan_speed * delta
	position += pan_velocity
	pan_velocity *= 0.9
	zoom = zoom.lerp(target_zoom, 0.3)

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
	
	if Input.is_action_just_pressed("pan_camera"):
		pan_mouse_start_position = get_local_mouse_position()
