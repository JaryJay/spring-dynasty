@tool
extends Squad
class_name AiSquad

enum Intelligence {
	LEAGUE_PLAYER,
	NORMAL,
	FIERCE,
	REMORSELESS,
}

@export var intelligence: Intelligence = Intelligence.NORMAL
