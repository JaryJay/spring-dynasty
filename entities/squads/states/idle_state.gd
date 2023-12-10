extends State
class_name IdleState

@export var attacking_state: AttackingState

func _enter_state(squad: Squad) -> void:
	# Uncomment the following line to debug
#	squad.debug_label.show()
	squad.debug_label.text = "Idle"
	for unit in squad.units:
		unit.play_animation("idle", randf_range(0.9, 1.1))
		unit.scale.x = 1
	squad.banner.play_animation("idle")

func process(squad: Squad) -> void:
	handle_pushing(squad)
	detect_enemies(squad)

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

func detect_enemies(squad: Squad) -> void:
	var closest_enemy: Squad
	var closest_dist: float = INF
	
	for body in squad.awareness_area.get_overlapping_bodies():
		if not body is Squad or body.is_friendly_to(squad.team) or not body.is_alive():
			continue
		if squad.position.distance_squared_to(body.position) < closest_dist:
			closest_dist = squad.position.distance_squared_to(body.position)
			closest_enemy = body
	
	if closest_enemy and closest_dist < squad.engage_range ** 2:
		attacking_state.target = closest_enemy
		squad.state_machine.state = attacking_state

func _exit_state(squad: Squad) -> void:
	squad.debug_label.hide()
