extends AttackingState

func process(squad: Squad) -> void:
	super(squad)
	
	if not target is Building:
		return
	var closest_enemy_squad: Squad = squad.get_closest_enemy_squad()
	if closest_enemy_squad:
		target = closest_enemy_squad
