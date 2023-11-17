extends Camera2D

@export_range(0, 500) var pan_speed: = 300.0

var disable_pan: = false

var pan_velocity: Vector2 = Vector2.ZERO
var target_zoom: Vector2 = Vector2.ONE

func _process(delta):
	if not disable_pan:
		var input_vector: = Input.get_vector("pan_left", "pan_right", "pan_up", "pan_down")
		if not input_vector.is_zero_approx():
			pan_velocity = input_vector.normalized() * pan_speed * delta
	
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
	
