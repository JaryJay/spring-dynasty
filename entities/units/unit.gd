extends Node2D
class_name Unit

@onready var anim_player: = $AnimationPlayer

func play_animation(animation_name: StringName, speed: float = 1) -> void:
	if not anim_player.current_animation == animation_name:
		anim_player.play(animation_name)
		anim_player.speed_scale = speed
