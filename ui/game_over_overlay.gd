extends ColorRect
class_name GameOverOverlay

var squads_slain: int
var squads_trained: int
var structures_captured: int
var players_eliminated: int
var time_survived: int
var total_score: int

func _ready() -> void:
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
