extends State
class_name NavigatingState

@export var repositioning_state: RepositioningState

func _enter_state(squad: Squad) -> void:
	# Uncomment the following line to debug
#	squad.debug_label.show()
	squad.debug_label.text = "Navigating"

func process(squad: Squad) -> void:
	var nav: = squad.nav
	if nav.is_navigation_finished():
		squad.state_machine.state = repositioning_state
		squad.velocity = Vector2.ZERO
	else:
		var next_path_position: Vector2 = nav.get_next_path_position()
		var direction: Vector2 = squad.global_position.direction_to(next_path_position)
		squad.rotate_and_move(direction)

func _exit_state(squad: Squad):
	squad.debug_label.hide()
