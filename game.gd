extends Node2D

class_name Game

@onready var selection_rect: SelectionRect = $SelectionRect
@onready var pause_menu: Control = $CanvasLayer/PauseMenu

var client_is_paused: bool = false
var selected_squads: Array[Squad] = []
var controlled_team: int = 0

func _ready():
	var pause_menu_resume_button: Button = $CanvasLayer/PauseMenu/Panel/VBoxContainer/Resume
	pause_menu_resume_button.pressed.connect(_on_pause_menu_resume_pressed)

func _process(_delta):
	if client_is_paused:
		pause_menu.show()
	else:
		pause_menu.hide()
	
	if selection_rect.is_selecting:
		for selected_squad in selected_squads:
			selected_squad.selected = false
		selected_squads.clear()
		for body in selection_rect.get_overlapping_bodies():
			if body is Squad:
				if body.team == controlled_team:
					selected_squads.append(body)
					body.selected = true
			else:
				print("Selected body is not a squad: %s" % body)

func _input(_event):
	if _event.is_action_pressed("ui_cancel"):
		client_is_paused = !client_is_paused
	
	var selecting: = Input.is_action_pressed("select")
	if Input.is_action_pressed("primary") and not selecting:
		var mouse_pos: = get_global_mouse_position()
		for squad in selected_squads:
			squad.set_target_position(mouse_pos)

func _on_pause_menu_resume_pressed():
	client_is_paused = false
