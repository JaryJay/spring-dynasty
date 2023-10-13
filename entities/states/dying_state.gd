extends State
class_name DyingState

var frames_until_deletion: = 60

func process(squad: Squad) -> void:
	if frames_until_deletion == 0:
		squad.queue_free()
	else:
		frames_until_deletion -= 1
