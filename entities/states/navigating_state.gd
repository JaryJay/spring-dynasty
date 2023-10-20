extends State
class_name NavigatingState

@export var idle_state: IdleState
@export var repositioning_state: RepositioningState

var actual_velocity

func _enter_state(squad: Squad) -> void:
	# Uncomment the following line to debug
#	squad.debug_label.show()
	squad.debug_label.text = "Navigating"
	for unit in squad.units:
		unit.play_animation("run")
	squad.banner.play_animation("moving")

func process(squad: Squad) -> void:
	var nav: = squad.nav
	if nav.is_navigation_finished():
		squad.state_machine.state = idle_state
		squad.velocity = Vector2.ZERO
	else:
		var colliding_rays: Array[RayCast2D] = []
		var non_colliding_rays: Array[RayCast2D] = []
		
		for _ray in squad.rays.get_children():
			var ray: RayCast2D = _ray
			if ray.is_colliding():
				colliding_rays.append(ray)
			else:
				non_colliding_rays.append(ray)
		
		var next_path_position: Vector2 = nav.get_next_path_position()
		var direction: Vector2 = squad.global_position.direction_to(next_path_position)
		if colliding_rays.size() > 0:
			
			if non_colliding_rays.size() == 0:
				# All rays are colliding. Let's just stop moving
				squad.state_machine.state = idle_state
				squad.velocity = Vector2.ZERO
			else:
				
#				var avg_non_colliding_ray: = Vector2.ZERO
#				for ray in non_colliding_rays:
#					avg_non_colliding_ray += Vector2.from_angle(ray.global_rotation)
#				avg_non_colliding_ray /= non_colliding_rays.size()
#				if avg_non_colliding_ray.is_zero_approx():
#					squad.rotate_and_move(direction)
#				else:
#					direction = direction.lerp(avg_non_colliding_ray.normalized(), 0.1).normalized()
#					squad.rotate_and_move(direction)
#				direction = direction.lerp(Vector2.from_angle(non_colliding_rays[0].global_rotation), 0.1).normalized()
				squad.rotate_and_move(direction)
		else:
			squad.rotate_and_move(direction)

func _exit_state(squad: Squad):
	squad.debug_label.hide()
