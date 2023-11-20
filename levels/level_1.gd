extends Level

func _ready() -> void:
	var squad: = preload("res://entities/footman_squad.tscn").instantiate()
	$Entities.add_child(squad)
	squad.position = $CampaignMap1/SpawnLocations/Team0.position
