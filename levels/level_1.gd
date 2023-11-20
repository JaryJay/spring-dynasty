extends Level

func _ready() -> void:
	var squad: = preload("res://entities/footman_squad.tscn").instantiate()
	$Entities.add_child(squad)
	squad.position = $CampaignMap1/SpawnLocations/Team0.position
	
	Server.lobby.player_ids.append(1)
	Server.lobby.player_info_list.append({ "team": 0 })
	Server.lobby.player_names.append("spongebob")
	
	super()
	set_physics_process(true)

func _physics_process(_delta) -> void:
	frame += 1
	
	# Update selected_squads to be the squads overlapped by selection_rect
	_update_squads_selection()
	
	# Note that detecting inputs is not the same as handling them
	var input: ClientInput = _detect_input()
	_add_input(input)
	
	# Handle inputs from all players, including the local player
	rollback_and_resimulate()
