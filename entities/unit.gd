extends Node2D
class_name Unit

@onready var anim_player: = $AnimationPlayer

func play_animation(animation_name: StringName) -> void:
	anim_player.play(animation_name)
