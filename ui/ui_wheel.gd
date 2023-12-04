@tool
extends Node2D

func _on_child_entered_tree(node: Node):
	print_debug("%s entered tree" % node.name)

func _on_child_exiting_tree(node: Node):
	print_debug("%s exited tree" % node.name)
