@tool
extends Node2D

@onready var anim_player: = $AnimationPlayer

var team_index: int = 0 : set = _set_team_index

func _set_team_index(value: int) -> void:
	if value >= 0 and value < TeamColors.colors.size():
		team_index = value
		$Banner.modulate = TeamColors.colors[team_index]
	else:
		printerr("Invalid color index: %d" % value)

func play_animation(animation_name: StringName, speed: float = 1) -> void:
	if not anim_player.current_animation == animation_name:
		anim_player.play(animation_name)
		anim_player.speed_scale = speed
