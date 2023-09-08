extends Node2D

class_name Game

var is_server: = false

@onready var selection_rect: SelectionRect = $SelectionRect
@onready var pause_menu: Control = $CanvasLayer/PauseMenu

var selected_squads: Array[Squad] = []
var controlled_team: int = 0

func _ready():
	controlled_team = Client.team_number
	
	var pause_menu_resume_button: Button = $CanvasLayer/PauseMenu/Panel/VBoxContainer/Resume
	pause_menu_resume_button.pressed.connect(pause_menu.hide)

func _process(_delta):
	
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
		pause_menu.visible = !pause_menu.visible
	
	var selecting: = Input.is_action_pressed("select")
	if Input.is_action_pressed("primary") and not selecting:
		var mouse_pos: = get_global_mouse_position()
		var space_state = get_world_2d().direct_space_state
		var query: = PhysicsPointQueryParameters2D.new()
		query.position = mouse_pos
		query.collision_mask = 1 # Collide with squads
		
		var collisions: = space_state.intersect_point(query)
		
		if collisions.size() == 0:
			_navigate_squads_to_point(mouse_pos)
			return
		
		# The enemy squad closest to the cursor
		var closest_enemy_squad: Squad
		var closest_dist_squared: = INF
		for collision in collisions:
			var collider: CollisionObject2D = collision.collider
			if collider is Squad and not collider.team == controlled_team:
				var enemy_squad: Squad = collider
				var dist_squared: = mouse_pos.distance_squared_to(enemy_squad.position)
				if dist_squared < closest_dist_squared:
					closest_enemy_squad = enemy_squad
					closest_dist_squared = dist_squared
		
		if closest_enemy_squad:
			for squad in selected_squads:
				var chasing_state: = squad.state_machine.get_node("ChasingState")
				chasing_state.chased_squad = closest_enemy_squad
				squad.state_machine.state = chasing_state
		else:
			# This will happen if all clicked squads are friendly
			_navigate_squads_to_point(mouse_pos)

func _navigate_squads_to_point(point: Vector2) -> void:
	for squad in selected_squads:
		squad.set_target_position(point)
		squad.state_machine.state = squad.state_machine.get_node("NavigatingState")
