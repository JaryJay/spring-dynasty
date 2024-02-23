class_name City extends Node2D

var team: int : set = set_team

func _ready() -> void:
	if team:
		set_team(team)

func set_team(_team: int) -> void:
	$Sprites/Fill.modulate = TeamColors.get_color(_team)
	team = _team
