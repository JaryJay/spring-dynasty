extends State
class_name NavigatingState

@export var idle_state: IdleState
@export var chasing_state: ChasingState

func _enter_state(squad: Squad) -> void:
	# Uncomment the following line to debug
#	squad.debug_label.show()
	squad.debug_label.text = "Navigating"
	for unit in squad.units:
		unit.play_animation("run")
	squad.banner.play_animation("moving")

func process(squad: Squad) -> void:
	var nav: = squad.nav
	if nav.is_navigation_finished():
		squad.state_machine.state = idle_state
		squad.velocity = Vector2.ZERO
	else:
		squad.set_target_position(squad.nav.target_position)
		var next_path_position: Vector2 = nav.get_next_path_position()
		squad.rotate_and_move(squad.global_position.direction_to(next_path_position))
		
		# If there is an enemy in front of the squad, then start
		# chasing that enemy
		for ray: RayCast2D in squad.rays.get_children():
			ray.force_raycast_update()
			if not ray.is_colliding(): continue
			
			var s: = ray.get_collider()
			if s is Squad and not s.is_friendly_to(squad.team) and s.is_alive():
				chasing_state.target = s
				squad.state_machine.state = chasing_state
				return

func _exit_state(squad: Squad):
	squad.debug_label.hide()
