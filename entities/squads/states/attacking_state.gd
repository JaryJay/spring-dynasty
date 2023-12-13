extends State
class_name AttackingState

@export var idle_state: IdleState
@export var chasing_state: ChasingState

var target: Node2D
var cooldown: int = 0

func _enter_state(squad: Squad) -> void:
	# Uncomment the following line to debug
	squad.debug_label.show()
	squad.debug_label.text = "Attacking"
	for unit in squad.units:
		unit.play_animation("idle")
	squad.banner.play_animation("idle")

func process(squad: Squad) -> void:
	handle_pushing(squad)
	if not is_instance_valid(target):
		squad.state_machine.state = idle_state
		return
	elif target is Squad and not target.is_alive():
		squad.state_machine.state = idle_state
		return
	elif target is Building and target.is_friendly_to(squad.team):
		squad.state_machine.state = idle_state
		return
	
	if squad.position.distance_to(target.position) < squad.range:
		if cooldown == 0:
			target.change_health(-squad.attack, squad)
			cooldown = squad.attack_cooldown
			squad.attack_particles.emitting = true
			
			var speed: = 1.0 * Engine.physics_ticks_per_second / squad.attack_cooldown
			for unit in squad.units:
				unit.play_animation("attack", speed)
		cooldown -= 1
		
		# Update unit visual direction (left or right)
		var scale_x: = signf(Vector2.RIGHT.dot(target.position - squad.position))
		if not is_zero_approx(scale_x):
			for unit in squad.units:
				unit.scale.x = scale_x
	else:
		chasing_state.target = target
		squad.state_machine.state = chasing_state

func _exit_state(squad: Squad) -> void:
	squad.debug_label.hide()
	target = null

# Override
func _requires_target() -> bool:
	return true
