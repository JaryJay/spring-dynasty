extends State
class_name AttackingState

@export var repositioning_state: RepositioningState
@export var chasing_state: ChasingState

var attacked_squad: Squad

func _enter_state(squad: Squad) -> void:
	# Uncomment the following line to debug
	squad.debug_label.show()
	squad.debug_label.text = "Attacking"
	for unit in squad.units:
		unit.play_animation("attack")

func process(squad: Squad) -> void:
	if attacked_squad.state_machine.state is DyingState:
		squad.state_machine.state = repositioning_state
		return
	
	if squad.position.distance_to(attacked_squad.position) < squad.range:
		# TODO: take squad attack speed into account
		attacked_squad.health -= squad.attack
	else:
		chasing_state.chased_squad = attacked_squad
		squad.state_machine.state = chasing_state

func _exit_state(squad: Squad) -> void:
	squad.debug_label.hide()
	attacked_squad = null
