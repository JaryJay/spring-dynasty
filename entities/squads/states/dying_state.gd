extends State
class_name DyingState

## Number of frames that the unit will stay on-screen for until it
## actually disappears
var frames_until_deletion: = 1 * Engine.physics_ticks_per_second

func _enter_state(squad: Squad) -> void:
	# Uncomment the following line to debug
#	squad.debug_label.show()
	squad.debug_label.text = "Dying"
	for unit in squad.units:
		unit.play_animation("die", randf_range(0.9, 1.1))
	squad.banner.play_animation("die")
	squad.collision_layer = 0
	squad.selected = false

func process(squad: Squad) -> void:
	if frames_until_deletion == 0:
		squad.queue_free()
	else:
		frames_until_deletion -= 1
