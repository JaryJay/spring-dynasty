extends State
class_name DyingState

## Number of frames that the unit will stay on-screen for until it
## actually disappears
var frames_until_deletion: = 30

func _enter_state(squad: Squad) -> void:
	# Uncomment the following line to debug
#	squad.debug_label.show()
	squad.debug_label.text = "Dying"
	for unit in squad.units:
		unit.play_animation("idle")
	squad.banner.play_animation("idle")

func process(squad: Squad) -> void:
	if frames_until_deletion == 0:
		squad.queue_free()
	else:
		frames_until_deletion -= 1
