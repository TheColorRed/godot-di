class_name Injector

static var META_NAME: String = '__injectables__'

## Provides an injectable to a node and it's children.
## * [type] is the injectable class to provide. This can be an instance of Injectable or InjectionToken.
## * [source] is the node to add the provider data to. This usually is set to [self] but can be any node.
## * [parameters] is an array of parameters to pass to the Injectable's constructor. If the [type] is an InjectionToken, this is the value to inject, such as a [Node], [String], [Int], etc.
static func provides(type: Variant, source: Variant = 'root', parameters: Variant = null) -> Variant:
	var klass: Variant

	if !(source is Node) and (source is String and source != 'root'):
		printerr('Injectable.provides: "source" must be a Node or "root".')
		push_error('Injectable.provides: "source" must be a Node or "root".')
		return null

	if type is InjectionToken or type is String:
		klass = Dictionary({ type = type, value = parameters })
	else:
		var params = []
		if parameters is Array:
			params = parameters
		else:
			if parameters != null:
				params.push_back(parameters)
		klass =	type.callv('new', params)


	if !is_instance_of(klass, Injectable) and !is_instance_of(type, InjectionToken) and !(type is String):
		printerr('Injectable.provides: "type" must be an instance of Injectable, InjectionToken, or String.')
		return null

	if source is String and source == 'root':
		print(Engine.get_main_loop())
		source = Engine.get_main_loop().root
		print(source)
	# Get the current injectables on the node.
	var meta: Array = source.get_meta(META_NAME, [])
	meta.push_back(klass)
	source.set_meta(META_NAME, meta)

	if is_instance_of(type, InjectionToken):
		return klass.value
	return klass


## Gets an injectable or a node.
## [b]Note:[/b] It is not advised to use this function in [_process] or [_physics_process].
## * [type] is the injectable class to inject into the node.
## * [source] is the node to start looking for the injectable. This usually is set to [self].
## * [multi] is a boolean that determines if multiple injectables should be returned. This climbs all the way to the top of the node tree and returns an array of all the injectables that were found.
static func inject(type: Variant, source: Variant = 'root', multi = false) -> Variant:
	return _find_injectable(type, source, multi)


static func _find_injectable(type: Variant, source: Variant, multi: bool, multiple: Array = []) -> Variant:
	if source is String and source == 'root':
		source = Engine.get_main_loop().root
	var meta: Array = source.get_meta(META_NAME, [])

	# Loop through the injectables on the node and check if they match the type.
	for injectable in meta:
		# If the injectable is a string, check if the type is a string and if they match.
		if type is String:
			if injectable is Dictionary and injectable.type is String and injectable.type == type:
				if multi:
					multiple.push_back(injectable.value)
				else:
					return injectable.value
		# If the injectable is an InjectionToken, check if the type is an InjectionToken and if they match.
		elif type is InjectionToken:
			if injectable is Dictionary and injectable.type is InjectionToken and injectable.type.token_name == type.token_name:
				if multi:
					multiple.push_back(injectable.value)
				else:
					return injectable.value
		# If the injectable is an instance of the type, return it.
		elif is_instance_of(injectable, type):
			if multi:
				multiple.push_back(injectable)
			else:
				return injectable

	# If this is to return an array of injectables, return it once we've reached the top of the node tree.
	if multi == true and source.get_parent() == null:
		return multiple

	# If we haven't found the injectable, check the parent node.
	if source.get_parent():
		return _find_injectable(type, source.get_parent(), multi, multiple)

	# If we still haven't found the injectable, return null.
	return null
