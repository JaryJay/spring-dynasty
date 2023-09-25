extends Node
class_name State

func _enter_state(_squad: Squad) -> void:
	pass

func process(_squad: Squad) -> void:
	pass

func _exit_state(_squad: Squad) -> void:
	pass

func _requires_target_squad() -> bool:
	return false
