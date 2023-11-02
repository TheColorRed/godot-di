class_name Injectable

static var META_NAME: String = '__injectables__'

## Provides an injectable to a node and it's children.
## [type] is the injectable class to provide. This can be an instance of Injectable or InjectionToken.
## [source] is the node to add the provider to. This usually is set to [self].
## [parameters] is an array of parameters to pass to the Injectable's constructor. If the [type] is an InjectionToken, this is the value to inject, such as a [Node], [String], [Int], etc.
static func provides(type: Variant, source: Node, parameters: Variant = null) -> Variant:
	var klass: Variant

	if type is InjectionToken:
		klass = Dictionary({ type = type, value = parameters })
	else:
		var params = []
		if parameters is Array:
			params = parameters
		else:
			if parameters != null:
				params.push_back(parameters)
		klass =	type.callv('new', params)

	if !is_instance_of(klass, Injectable) and !is_instance_of(type, InjectionToken):
		printerr('Injectable.provides: type must be an instance of Injectable or InjectionToken')
		return null

	# Get the current injectables on the node.
	var meta: Array = source.get_meta(META_NAME, [])
	meta.push_back(klass)
	source.set_meta(META_NAME, meta)

	if is_instance_of(type, InjectionToken):
		return klass.value
	return klass


## Gets an injectable or a node
## [type] is the injectable class to inject into the node.
## [source] is the current node. This usually is set to [self].
## [multi] is a boolean that determines if multiple injectables should be returned.
static func inject(type: Variant, source: Node, multi = false) -> Variant:
	return _find_injectable(type, source, multi)


static func _find_injectable(type: Variant, source: Node, multi: bool, multiple: Array = []) -> Variant:
	var meta: Array = source.get_meta(META_NAME, [])

	for injectable in meta:
		if type is InjectionToken:
			if injectable is Dictionary and injectable.type.token_name == type.token_name:
				if multi:
					multiple.push_back(injectable.value)
				else:
					return injectable.value
		elif is_instance_of(injectable, type):
			if multi:
				multiple.push_back(injectable)
			else:
				return injectable

	if multi == true and source.get_parent() == null:
		return multiple

	if source.get_parent():
		return _find_injectable(type, source.get_parent(), multi, multiple)

	return null
