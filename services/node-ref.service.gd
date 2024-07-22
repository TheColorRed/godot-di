## A reference to the current node.
class_name NodeRef extends Injectable

var node: Variant

func _init(p_node: Variant=null) -> void:
	if p_node != null and p_node is Node:
		node = p_node