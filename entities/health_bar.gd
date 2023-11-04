extends Sprite2D

@export_range(0, 500) var max_health: int = 100
@export var full_health_color: Color
@export var empty_health_color: Color

@onready var bar: = $Bar
@onready var difference_bar: = $DifferenceBar
@onready var start_marker: = $StartMarker
@onready var end_marker: = $EndMarker
@onready var health_difference_timer: = $HealthDifferenceTimer
@onready var fade_timer: = $FadeTimer

var prev_health: int = -1

var _bar_tween: Tween
var _transparency_tween: Tween

func _ready():
	modulate = Color.TRANSPARENT

func on_health_changed(old: int, new: int) -> void:
	if _bar_tween and _bar_tween.is_valid():
		_bar_tween.kill()
	if _transparency_tween and _transparency_tween.is_valid():
		_transparency_tween.kill()
	
	bar.scale.x = 1.0 * new / max_health
	bar.color = empty_health_color.lerp(full_health_color, bar.scale.x)
	
	prev_health = maxi(prev_health, old)
	difference_bar.position = start_marker.position.lerp(end_marker.position, 1.0 * new / max_health)
	difference_bar.scale = Vector2(1.0 * (prev_health - new) / max_health, 1)
	
	modulate = Color.WHITE
	
	# Restart timers
	health_difference_timer.stop()
	health_difference_timer.start()
	fade_timer.stop()
	fade_timer.start()

func _process(_delta):
	difference_bar.scale.x *= 0.9

func _on_health_difference_timer_timeout():
	_bar_tween = create_tween()
	#_bar_tween.tween_property(difference_bar, "scale", Vector2(0, 1), .5).from_current().set_ease(Tween.EASE_OUT)
	_bar_tween.tween_property(self, "prev_health", -1, .5)

func _on_fade_timer_timeout():
	_transparency_tween = create_tween()
	_transparency_tween.tween_property(self, "modulate", Color.TRANSPARENT, .5)
