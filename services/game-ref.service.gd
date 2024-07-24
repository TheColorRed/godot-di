class_name GameRef extends Injectable

func _init():
	provided_in = 'root'

## Gets the game's window.
var root: Window:
	get: return Engine.get_main_loop().get_root()

## Gets the game's scene tree.
var tree: SceneTree:
	get: return root.get_tree()