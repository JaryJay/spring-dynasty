extends Node2D

const game_scene: = preload("res://game.tscn")

func _on_button_pressed():
	get_tree().change_scene_to_packed(game_scene)
