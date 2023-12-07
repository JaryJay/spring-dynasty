@tool
extends Node2D
class_name UIWheel

static var current_ui_wheel: UIWheel

@onready var control: = $Control

@export_range(1, 100) var radius: float = 56 :
	set(val):
		radius = val
		set_element_positions()
@onready var display: = false : set = _set_display

func _ready() -> void:
	if Engine.is_editor_hint(): return
	$Sprite2D.modulate = Color.TRANSPARENT
	$Sprite2D.scale = Vector2.ZERO
	for node: Node in get_children():
		if node is UIWheelElement:
			node.modulate = Color.TRANSPARENT
			node.position = Vector2.ZERO

func _on_child_entered_tree(node: Node) -> void:
	if Engine.is_editor_hint(): return
	if node is UIWheelElement:
		set_element_positions()
func _on_child_exiting_tree(node: Node) -> void:
	if Engine.is_editor_hint(): return
	if node is UIWheelElement:
		set_element_positions()

func _set_display(val: bool) -> void:
	display = val
	
	var elements: Array[UIWheelElement] = []
	for node: Node in get_children():
		if node is UIWheelElement:
			elements.append(node)
	var num: = elements.size()
	
	if not display:
		var tw: = create_tween().set_parallel(true)
		for e: UIWheelElement in elements:
			tw.tween_property(e, "position", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_CUBIC)
			tw.tween_property(e, "modulate", Color.TRANSPARENT, 0.2).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property($Sprite2D, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property($Sprite2D, "modulate", Color.TRANSPARENT, 0.2).set_trans(Tween.TRANS_CUBIC)
		
		tw = tw.chain()
		for e: UIWheelElement in elements:
			tw.tween_callback(e.hide)
		tw.tween_callback($Sprite2D.hide)
	else:
		$Sprite2D.show()
		
		var tw: = create_tween().set_parallel(true)
		for i: int in num:
			var e: UIWheelElement = elements[i]
			e.show()
			var target_pos: = (Vector2.UP.rotated(i * TAU / num)) * radius
			tw.tween_property(e, "position", target_pos, 0.2).set_trans(Tween.TRANS_CUBIC)
			tw.tween_property(e, "modulate", Color.WHITE, 0.2).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property($Sprite2D, "scale", Vector2(2, 2), 0.2).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property($Sprite2D, "modulate", Color.WHITE, 0.2).set_trans(Tween.TRANS_CUBIC)

func set_element_positions() -> void:
	var elements: Array[UIWheelElement] = []
	for node: Node in get_children():
		if node is UIWheelElement:
			elements.append(node)
	
	var num: = elements.size()
	for i: int in num:
		elements[i].position = (Vector2.UP.rotated(i * TAU / num)) * radius

func _on_control_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("secondary_interact"):
		control.accept_event()
		if current_ui_wheel:
			if current_ui_wheel == self:
				display = false
				current_ui_wheel = null
				return
			else:
				current_ui_wheel.display = false
		display = true
		current_ui_wheel = self
