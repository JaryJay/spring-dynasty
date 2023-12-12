extends Node
class_name State

func _enter_state(_squad: Squad) -> void:
	pass

func process(_squad: Squad) -> void:
	pass

func _exit_state(_squad: Squad) -> void:
	pass

func _requires_target() -> bool:
	return false

func handle_pushing(squad: Squad) -> void:
	var push_area: Area2D = squad.push_area
	var pushing_bodies: = push_area.get_overlapping_bodies()
	if not pushing_bodies.size():
		return
	
	var avg_push_dir: = Vector2.ZERO
	var pushing_count: = 0
	for _s in pushing_bodies:
		if not _s is Squad:
			continue
		var s: Squad = _s
		var s_state: = s.state_machine.state
		if s_state is NavigatingState or s_state is IdleState:
			avg_push_dir += s.position.direction_to(squad.position)
			pushing_count += 1
	
	if pushing_count:
		avg_push_dir = (avg_push_dir / pushing_count)
		if not avg_push_dir.is_zero_approx():
			squad.rotate_and_move(avg_push_dir.normalized(), 0.5)
