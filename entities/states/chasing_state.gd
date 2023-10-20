extends State
class_name ChasingState

@export var idle_state: IdleState
@export var attacking_state: AttackingState

var target_squad: Squad

func _enter_state(squad: Squad) -> void:
	# Uncomment the following line to debug
	squad.debug_label.show()
	squad.debug_label.text = "Chasing"
	for unit in squad.units:
		unit.play_animation("run")
	squad.banner.play_animation("moving")

func process(squad: Squad) -> void:
	if target_squad.state_machine.state is DyingState:
		squad.state_machine.state = idle_state
		return
	
	squad.set_target_position(target_squad.position)
	
	if squad.position.distance_to(target_squad.position) < squad.engage_range:
		attacking_state.target_squad = target_squad
		squad.state_machine.state = attacking_state
		squad.velocity = Vector2.ZERO
	else:
		var nav: = squad.nav
		var next_path_position: Vector2 = nav.get_next_path_position()
		var direction: Vector2 = squad.global_position.direction_to(next_path_position)
		squad.rotate_and_move(direction)

func _exit_state(_squad: Squad) -> void:
#	squad.debug_label.hide()
	pass
#	target_squad = null

# Override
func _requires_target_squad() -> bool:
	return true
