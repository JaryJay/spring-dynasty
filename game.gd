extends Node2D

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
	var selecting: = Input.is_action_pressed("select")
	if Input.is_action_just_released("primary") and not selecting:
		var mouse_pos: = get_global_mouse_position()
		for squad in selected_squads:
			squad.nav.target_position = mouse_pos
