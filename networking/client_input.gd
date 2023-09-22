extends Resource
class_name ClientInput

var frame: int
var state: StringName
var squads: PackedStringArray

# Only one of (target, enemy_squad) will be used
var target: Vector2
var enemy_squad: StringName

func _init(frame: int, state: StringName, squads: PackedStringArray,
	target: Vector2, enemy_squad: StringName = ""):
		self.frame = frame
		self.state = state
		self.squads = squads
		self.target = target
		self.enemy_squad = enemy_squad
