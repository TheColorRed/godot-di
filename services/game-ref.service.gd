class_name GameRef extends Injectable

func _init():
	provided_in = 'root'

var root: Window:
	get: return Engine.get_main_loop().get_root()
