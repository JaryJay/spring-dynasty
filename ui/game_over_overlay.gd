extends ColorRect
class_name GameOverOverlay

var victory: bool = false

var squads_slain: int
var squads_trained: int
var structures_captured: int
var players_eliminated: int
var time_survived: int
var total_score: int

func _ready() -> void:
	if victory:
		$V/Label.text = "Victory"
		var comments: = [
			"Your enemies tremble beneath your feet.",
			"Good work, general.",
			"You are the victor.",
			"GG EZ",
		]
		%CommentLabel.text = comments.pick_random()
	
	%SquadsSlain.text = str(squads_slain)
	%SquadsTrained.text = str(squads_trained)
	%StructuresCaptured.text = str(structures_captured)
	%PlayersEliminated.text = str(players_eliminated)
	
	# Format number of frames as time
	var seconds: = time_survived / Engine.physics_ticks_per_second
	var seconds_str: String
	if seconds % 60 <= 9:
		seconds_str = "0" + str(seconds % 60)
	else:
		seconds_str = str(seconds % 60)
	%TimeSurvived.text = "%d:%s" % [seconds / 60, seconds_str]
	
	%TotalScore.text = str(total_score)
	
	for i in %RatingsContainer.get_children().size():
		var button: Button = %RatingsContainer.get_child(i)
		button.pressed.connect(_on_rating_clicked.bind(i + 1))

func _on_rating_clicked(number: int) -> void:
	Global.console.print("Player rated the game %d out of 5" % number)
	# TODO: somehow send this information to the server
	%RatingsContainer.hide()
	%ThanksLabel.show()

func _on_return_label_gui_input(event: InputEvent):
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("primary"):
		$V/ReturnLabel.mouse_filter = MOUSE_FILTER_IGNORE
		var tween: = create_tween()
		tween.tween_property(self, "modulate", Color.BLACK, 1).set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_property(self, "color", Color.BLACK, 1).set_trans(Tween.TRANS_CUBIC)
		tween.tween_callback(get_tree().change_scene_to_file.bind("res://ui/lobby_menu.tscn"))
