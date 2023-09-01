extends State
class_name RepositioningState

@export var idle_state: IdleState

func _enter_state(squad: Squad) -> void:
	# Uncomment the following line to debug
#	squad.debug_label.show()
	squad.debug_label.text = "Repositioning"

func process(squad: Squad) -> void:
	# These also include the squad itself
	var overlapping_squads: = squad.personal_space_area.get_overlapping_bodies()
	var overlapping_idle_or_repositioning_squads: = overlapping_squads.filter(_is_squad_idle_or_repositioning)
	
	if overlapping_squads.size() == 1:
		squad.state_machine.state = idle_state
		return
	
	for s in overlapping_idle_or_repositioning_squads:
		if s.team == squad.team and s.state_machine.state is IdleState:
			s.state_machine.state = s.state_machine.get_node("RepositioningState")
	
	# If overlapping too closely with 1 other squad, then move directly away from it
	if overlapping_idle_or_repositioning_squads.size() == 2:
		var other_index: = 1 if overlapping_idle_or_repositioning_squads[0] == squad else 0
		var other_squad: Squad = overlapping_idle_or_repositioning_squads[other_index]
		
		if other_squad is Squad and other_squad.position.distance_to(squad.position) < 30:
			squad.debug_label.text = "Colliding too close!"
			var dir: = other_squad.position.direction_to(squad.position)
			squad.rotate_and_move(dir.normalized())
			return
	
	for other_squad in overlapping_idle_or_repositioning_squads:
		if not other_squad == squad and other_squad.position.distance_to(squad.position) < 2:
			squad.position += other_squad.position.direction_to(squad.position) * 2

	# Otherwise, use raycasts to determine direction
	_reposition_using_raycasts(squad)

func _reposition_using_raycasts(squad: Squad) -> void:
	squad.debug_label.text = "Raycasting"
	var colliding_rays: Array[RayCast2D] = []
	var first_non_colliding_ray: RayCast2D
	
	for _ray in squad.rays.get_children():
		var ray: RayCast2D = _ray
		if ray.is_colliding():
			colliding_rays.append(ray)
		elif first_non_colliding_ray == null:
			first_non_colliding_ray = ray
	
	if colliding_rays.size() == squad.rays.get_child_count():
		# All rays are colliding
		squad.debug_label.text = "Desperate"
		var nav_final_position: = squad.nav.get_final_position()
		var dir: = -squad.position.direction_to(nav_final_position)
		squad.rotate_and_move(dir)
	elif colliding_rays.size() == 0:
		# This is not supposed to happen because there should always be a
		# colliding ray if there is another squad in our personal space
		squad.debug_label.text = "This is not supposed to happen!"
		var dir: = Vector2.DOWN.rotated(first_non_colliding_ray.global_rotation)
		squad.rotate_and_move(dir)
	else:
		var avg_colliding_ray_dir: = Vector2.ZERO
		for colliding_ray in colliding_rays:
			avg_colliding_ray_dir += Vector2.DOWN.rotated(colliding_ray.global_rotation)
		
		# Very important not to normalize a zero vector
		if not avg_colliding_ray_dir.is_zero_approx():
			avg_colliding_ray_dir = avg_colliding_ray_dir.normalized()
		
		var first_dir: = Vector2.DOWN.rotated(first_non_colliding_ray.global_rotation)
		
		# Point slightly away from the average colliding ray
		var dir: = first_dir.lerp(-avg_colliding_ray_dir, 0.1).normalized()
		squad.rotate_and_move(dir)

func _exit_state(squad: Squad):
	squad.debug_label.hide()

func _is_squad_idle_or_repositioning(sq: Squad) -> bool:
	var state: = sq.state_machine.state
	return state is IdleState or state is RepositioningState
