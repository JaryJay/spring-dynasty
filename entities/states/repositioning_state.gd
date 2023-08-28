extends State
class_name RepositioningState

@export var idle_state: IdleState

func process(squad: Squad) -> void:
	if squad.personal_space_area.get_overlapping_bodies().size() == 1:
		# The only thing in its person space is itself
		squad.state_machine.state = idle_state
	else:
		for _ray in squad.rays.get_children():
			var ray: RayCast2D = _ray
			if not ray.is_colliding():
				squad.rotate_and_move(Vector2.DOWN.rotated(ray.global_rotation) * squad.speed)
				return
		squad.rotate_and_move(-squad.position.direction_to(squad.nav.get_final_position()) * squad.speed)
