extends Node2D

class_name Game

signal client_pause_state_changed(client_is_paused: bool)
var client_pause_state: bool = false:
	get:
		return client_pause_state
	set(value):
		client_pause_state = value
		emit_signal("client_pause_state_changed", client_pause_state)

@onready var selection_rect: SelectionRect = $SelectionRect

var selected_squads: Array[Squad] = []

func _process(_delta):
	if selection_rect.is_selecting:
		for selected_squad in selected_squads:
			selected_squad.selected = false
		selected_squads.clear()
		for body in selection_rect.get_overlapping_bodies():
			if body is Squad:
				selected_squads.append(body)
				body.selected = true
			else:
				print("Selected body is not a squad: %s" % body)

func _input(_event):
	if _event.is_action_pressed("ui_cancel"):
		client_pause_state = !client_pause_state
	
	var selecting: = Input.is_action_pressed("select")
	if Input.is_action_pressed("primary") and not selecting:
		var mouse_pos: = get_global_mouse_position()
		for squad in selected_squads:
			squad.set_target_position(mouse_pos)
