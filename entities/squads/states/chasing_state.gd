extends State
class_name ChasingState

@export var idle_state: IdleState
@export var attacking_state: AttackingState

var target: Node2D

func _enter_state(squad: Squad) -> void:
	# Uncomment the following line to debug
	squad.debug_label.show()
	squad.debug_label.text = "Chasing"
	for unit in squad.units:
		unit.play_animation("run")
	squad.banner.play_animation("moving")

func process(squad: Squad) -> void:
	if not is_instance_valid(target):
		squad.state_machine.state = idle_state
		return
	elif target is Squad and not target.is_alive():
		squad.state_machine.state = idle_state
		return
	elif target is Building and target.is_friendly_to(squad.team):
		squad.state_machine.state = idle_state
		return
	
	var targ_pos: = target.position + target.position.direction_to(squad.position) * 10
	squad.set_target_position(targ_pos)
	
	if squad.position.distance_to(target.position) < squad.engage_range:
		attacking_state.target = target
		squad.state_machine.state = attacking_state
		squad.velocity = Vector2.ZERO
	else:
		var nav: = squad.nav
		var next_path_position: Vector2 = nav.get_next_path_position()
		var direction: Vector2 = squad.global_position.direction_to(next_path_position)
		squad.rotate_and_move(direction)
		
		# If there is an enemy in front of the squad, then start
		# chasing that enemy instead
		for ray: RayCast2D in squad.rays.get_children():
			ray.force_raycast_update()
			if not ray.is_colliding(): continue
			
			var s: = ray.get_collider()
			if s is Squad and not s.is_friendly_to(squad.team) and s.is_alive():
				target = s
				return

func _exit_state(_squad: Squad) -> void:
#	squad.debug_label.hide()
	pass
#	target = null

# Override
func _requires_target() -> bool:
	return true
