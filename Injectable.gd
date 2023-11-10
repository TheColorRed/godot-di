## The base class for all injectable classes.
## To clean up an injectable, add [_destroy()] to the class.
class_name Injectable extends Resource

## The reference to the node that this injectable is provided by.
## The second argument is the ref.
## Example: [Injector.provide('xxx', 'root')] making [node_ref = 'root']
var node_ref: Node
## Where this injectable will be provided.
static var provided_in: Variant = null
## Whether this injectable can be provided multiple times on the same node.
static var multi := false
