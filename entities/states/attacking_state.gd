extends State
class_name AttackingState

@export var idle_state: IdleState
@export var chasing_state: ChasingState

var target_squad: Squad
var cooldown: = 0

func _enter_state(squad: Squad) -> void:
	# Uncomment the following line to debug
	squad.debug_label.show()
	squad.debug_label.text = "Attacking"
	var speed: = roundf(1.0 * Engine.physics_ticks_per_second / squad.attack_cooldown)
	for unit in squad.units:
		unit.play_animation("attack", speed)
	squad.banner.play_animation("idle")

func process(squad: Squad) -> void:
	if target_squad.state_machine.state is DyingState:
		squad.state_machine.state = idle_state
		return
	
	if squad.position.distance_to(target_squad.position) < squad.range:
		if cooldown == 0:
			target_squad.health -= squad.attack
			cooldown = squad.attack_cooldown
			squad.attack_particles.emitting = true
		cooldown -= 1
		
		# Update unit visual direction (left or right)
		var scale_x: = signf(Vector2.RIGHT.dot(target_squad.position - squad.position))
		if not is_zero_approx(scale_x):
			for unit in squad.units:
				unit.scale.x = scale_x
	else:
		chasing_state.target_squad = target_squad
		squad.state_machine.state = chasing_state

func _exit_state(squad: Squad) -> void:
	squad.debug_label.hide()
	target_squad = null

# Override
func _requires_target_squad() -> bool:
	return true
