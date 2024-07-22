## A reference to the current node.
class_name NodeRef extends Injectable

var node: Node

func _init(p_node: Node=null) -> void:
	if p_node != null and p_node is Node:
		node = p_node