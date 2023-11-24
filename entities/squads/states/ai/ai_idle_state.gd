extends IdleState

@export var chasing_state: ChasingState

func process(squad: Squad) -> void:
	var closest_enemy_squad: Squad = squad.get_closest_enemy_squad()
	if closest_enemy_squad:
		chasing_state.target = closest_enemy_squad
		squad.state_machine.state = chasing_state
