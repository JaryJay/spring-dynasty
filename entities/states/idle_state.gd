extends State
class_name IdleState

func _enter_state(squad: Squad) -> void:
	# Uncomment the following line to debug
#	squad.debug_label.show()
	squad.debug_label.text = "Idle"

func process(_squad: Squad) -> void:
	# TODO: transition to ChasingState if there are enemies nearby
	return

func _exit_state(squad: Squad) -> void:
	squad.debug_label.hide()
