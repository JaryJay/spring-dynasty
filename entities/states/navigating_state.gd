extends State
class_name NavigatingState

@export var repositioning_state: RepositioningState

func process(squad: Squad) -> void:
	var nav: = squad.nav
	if nav.is_navigation_finished():
		squad.state_machine.state = repositioning_state
		squad.velocity = Vector2.ZERO
	else:
		var next_path_position: Vector2 = nav.get_next_path_position()
		var direction: Vector2 = squad.global_position.direction_to(next_path_position)
		squad.rotate_and_move(direction * squad.speed)
