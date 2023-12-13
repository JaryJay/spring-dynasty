extends Area2D
class_name SelectionRect

var select_corner: Vector2

func _input(_event) -> void:
	var selecting: = Input.is_action_pressed("select")
	
	if Input.is_action_just_pressed("select"):
		select_corner = get_global_mouse_position()
	if selecting:
		var mouse_pos: = get_global_mouse_position()
		position = select_corner.lerp(mouse_pos, 0.5)
		scale = mouse_pos - select_corner
	if Input.is_action_just_released("select"):
		select_corner = Vector2.ZERO
		scale = Vector2.ZERO
