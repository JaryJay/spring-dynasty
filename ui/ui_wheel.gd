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

func _on_child_entered_tree(node: Node) -> void:
	if node is UIWheelElement:
		set_element_positions()

func _on_child_exiting_tree(node: Node) -> void:
	if node is UIWheelElement:
		set_element_positions()

func _set_display(val: bool) -> void:
	display = val
	
	if not display:
		$Sprite2D.hide()
		for child: Node in get_children():
			if child is UIWheelElement:
				child.hide()
		return
	$Sprite2D.show()
	
	set_element_positions()
	
	var tw: = create_tween().set_parallel(true)
	for node: Node in get_children():
		if node is UIWheelElement:
			node.show()
			tw.tween_property(node, "position", node.position, 0.2).from(Vector2.ZERO).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property($Sprite2D, "scale", Vector2(2, 2), 0.2).from(Vector2.ZERO).set_trans(Tween.TRANS_CUBIC)

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
		Global.console.print("Hi!")
		control.accept_event()
		if current_ui_wheel and current_ui_wheel != self:
			display = false
		current_ui_wheel = self
		display = true
