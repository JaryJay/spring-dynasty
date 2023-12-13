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

func detect_enemies(squad: Squad) -> void:
	var closest_enemy: Squad
	var closest_dist: float = INF
	
	for other in squad.awareness_area.get_overlapping_bodies():
		if not other is Squad or other.is_friendly_to(squad.team) or not other.is_alive():
			continue
		var o_state: State = other.state_machine.state
		var dist: = squad.position.distance_squared_to(other.position)
		if dist < closest_dist:
			closest_dist = dist
			closest_enemy = other
	
	if closest_enemy and closest_dist < squad.engage_range ** 2:
		attacking_state.target = closest_enemy
		squad.state_machine.state = attacking_state

func _exit_state(squad: Squad) -> void:
	squad.debug_label.hide()
