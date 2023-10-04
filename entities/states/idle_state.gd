extends State
class_name IdleState

func _enter_state(squad: Squad) -> void:
	# Uncomment the following line to debug
#	squad.debug_label.show()
	squad.debug_label.text = "Idle"
	for unit in squad.units:
		unit.play_animation("idle")

func process(squad: Squad) -> void:
	handle_pushing(squad)
	return

func handle_pushing(squad: Squad) -> void:
	var push_area: Area2D = squad.push_area
	var pushing_squads: = push_area.get_overlapping_bodies()
	if not pushing_squads.size():
		return
	
	var avg_push_dir: = Vector2.ZERO
	var pushing_count: = 0
	for _s in pushing_squads:
		var s: Squad = _s
		if s.state_machine.state is NavigatingState:
			avg_push_dir += s.position.direction_to(squad.position)
			pushing_count += 1
	
	if pushing_count:
		avg_push_dir = (avg_push_dir / pushing_count)
		if not avg_push_dir.is_zero_approx():
			squad.rotate_and_move(avg_push_dir.normalized())

func _exit_state(squad: Squad) -> void:
	squad.debug_label.hide()
