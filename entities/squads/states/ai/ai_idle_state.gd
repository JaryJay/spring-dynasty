extends IdleState

@export var chasing_state: ChasingState

func process(_squad: Squad) -> void:
	var squad: = _squad as AiSquad
	
	var closest_enemy_squad: Squad = squad.get_closest_enemy_squad()
	if closest_enemy_squad:
		chasing_state.target = closest_enemy_squad
		squad.state_machine.state = chasing_state
		return
	
	if squad.intelligence < AiSquad.Intelligence.NORMAL: return
	
	# Check if any friendly squads are attacking things
	var target: Node2D = null
	var closest_friendly_distance: = INF
	for o: PhysicsBody2D in squad.awareness_area.get_overlapping_bodies():
		if not o is Squad or not o.is_friendly_to(squad.team) or not o.is_alive():
			continue
		
		var o_state: State = o.state_machine.state
		if o_state is AttackingState or o_state is ChasingState and o_state.target:
			var dist = squad.global_position.distance_squared_to(o.global_position)
			if dist < closest_friendly_distance:
				target = o_state.target
				closest_friendly_distance = dist
	if target:
		chasing_state.target = target
		squad.state_machine.state = chasing_state
