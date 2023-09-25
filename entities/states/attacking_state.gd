extends State
class_name AttackingState

@export var repositioning_state: RepositioningState
@export var chasing_state: ChasingState

var target_squad: Squad

func _enter_state(squad: Squad) -> void:
	# Uncomment the following line to debug
	squad.debug_label.show()
	squad.debug_label.text = "Attacking"
	for unit in squad.units:
		unit.play_animation("attack")

func process(squad: Squad) -> void:
	if target_squad.state_machine.state is DyingState:
		squad.state_machine.state = repositioning_state
		return
	
	if squad.position.distance_to(target_squad.position) < squad.range:
		# TODO: take squad attack speed into account
		target_squad.health -= squad.attack
	else:
		chasing_state.target_squad = target_squad
		squad.state_machine.state = chasing_state

func _exit_state(squad: Squad) -> void:
	squad.debug_label.hide()
	target_squad = null

# Override
func _requires_target_squad() -> bool:
	return true
