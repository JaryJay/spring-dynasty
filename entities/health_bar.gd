extends Sprite2D

@export var full_health_color: Color
@export var empty_health_color: Color

@onready var bar: = $Bar
@onready var difference_bar: = $DifferenceBar
@onready var start_marker: = $StartMarker
@onready var end_marker: = $EndMarker
@onready var health_difference_timer: = $HealthDifferenceTimer
@onready var fade_timer: = $FadeTimer

var max_health: int = 100
var prev_health: int = -1

var _bar_tween: Tween
var _transparency_tween: Tween

func _ready():
	modulate = Color.TRANSPARENT

func on_health_changed(old: int, new: int) -> void:
	bar.scale.x = 1.0 * new / max_health
	bar.color = empty_health_color.lerp(full_health_color, bar.scale.x)
	
	prev_health = maxi(prev_health, old)
	difference_bar.position = start_marker.position.lerp(end_marker.position, bar.scale.x)
	difference_bar.scale.x = (prev_health - new) / max_health
	
	modulate = Color.WHITE
	
	if _bar_tween:
		_bar_tween.kill()
	if _transparency_tween:
		_transparency_tween.kill()
	
	# Restart timers
	health_difference_timer.stop()
	health_difference_timer.start()
	fade_timer.stop()
	fade_timer.start()

func _on_health_difference_timer_timeout():
	_bar_tween = create_tween()
	_bar_tween.tween_property(difference_bar, "scale:x", 0, .5)

func _on_fade_timer_timeout():
	_transparency_tween = create_tween()
	_transparency_tween.tween_property(self, "modulate", Color.TRANSPARENT, .5)
