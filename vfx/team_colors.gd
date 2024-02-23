extends Node
class_name TeamColors

const image:  = preload("res://assets/textures/misc/team_colors.png")

# Deprecated
const colors: Array[Color] = [
	Color(6 / 255.0, 180 / 255.0, 216 / 255.0),
	Color(234 / 255.0, 79 / 255.0, 65 / 255.0),
	Color(82 / 255.0, 163 / 255.0, 41 / 255.0),
	Color(192 / 255.0, 159 / 255.0, 25 / 255.0),
	Color(169 / 255.0, 141 / 255.0, 245 / 255.0),
	Color(166 / 255.0, 99 / 255.0, 46 / 255.0),
	Color(0 / 255.0, 0 / 255.0, 0 / 255.0),
	Color(67 / 255.0, 67 / 255.0, 67 / 255.0),
]

static func get_color(team: int) -> Color:
	return image.get_image().get_pixel(team % 4, team / 4)
