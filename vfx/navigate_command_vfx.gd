extends Node2D

func _ready():
	$AnimationPlayer.play("default")
	
func _on_animation_player_animation_finished(_anim_name):
	queue_free()
