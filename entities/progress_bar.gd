@tool
extends Sprite2D

@export_range(0, 500) var max_value: int = 100
@export var full_color: Color :
	set(val):
		full_color = val
		if Engine.is_editor_hint() and is_node_ready():
			$Bar.color = full_color
@export var empty_color: Color
@export_range(0, 3) var fade_time: float = 1

@onready var bar: = $Bar
@onready var start_marker: = $StartMarker
@onready var end_marker: = $EndMarker
@onready var fade_timer: = $FadeTimer

var _transparency_tween: Tween

func _ready():
	if Engine.is_editor_hint():
		bar.color = full_color
		return
	modulate = Color.TRANSPARENT
	if fade_time > 0:
		fade_timer.wait_time = fade_time

func on_value_changed(_old: int, new: int) -> void:
	if _transparency_tween and _transparency_tween.is_valid():
		_transparency_tween.kill()
	
	new = maxi(new, 0)
	
	bar.scale.x = 1.0 * new / max_value
	bar.color = empty_color.lerp(full_color, bar.scale.x)
	
	modulate = Color.WHITE
	
	# Restart timers
	if fade_time > 0:
		fade_timer.stop()
		fade_timer.start()

func _on_fade_timer_timeout():
	_transparency_tween = create_tween()
	_transparency_tween.tween_property(self, "modulate", Color.TRANSPARENT, .5)
