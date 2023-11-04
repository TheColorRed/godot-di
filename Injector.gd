## A class that manages injectables.
## Valid injectables include:
## * [Injectable] &ndash; A class that extends Injectable.
## * [InjectionToken] &ndash; A class that instantiates an InjectionToken.
## * [String] &ndash; A string that matches the name of an InjectionToken or another string.
extends Node

## The name of the meta data that is added to nodes.
var META_NAME: String = '__injectables__'
## A list of nodes that have injectables.
var nodes_with_injectables: Array = []


## Provides an injectable to a node and it's children.
## * [type] &ndash; is the injectable class to provide. This can be an instance of Injectable or InjectionToken.
## * [source] &ndash; is the node to add the provider data to. This usually is set to [self] but can be any node.
## * [parameters] &ndash; is an array of parameters to pass to the Injectable's constructor. If the [type] is an InjectionToken, this is the value to inject, such as a [Node], [String], [Int], etc.
func provide(type: Variant, source: Variant = 'root', parameters: Variant = null) -> Variant:
	var klass: Variant

	# When we add a new provider, we will set up a signal to clear the injectables when the scene is exited if one doesn't already exist.
	if !get_tree().current_scene.tree_exiting.is_connected(_on_tree_exiting):
		get_tree().current_scene.tree_exiting.connect(_on_tree_exiting)

	# If the source is not a node or 'root', return null.
	if !(source is Node) and (source is String and source != 'root'):
		printerr('Injectable.provide: "source" must be a Node or "root".')
		push_error('Injectable.provide: "source" must be a Node or "root".')
		return null

	# If the source is 'root', set the source to the root node.
	if source is String and source == 'root':
		source = get_tree().root

	# If the type is an InjectionToken or string, create a dictionary with the type and value.
	if type is InjectionToken or type is String:
		if(typeof(parameters) == TYPE_OBJECT and !(parameters is Node)):
			var i = _create_injectable(parameters, source, null)
			if i is Injectable:
				parameters = i
		klass = Dictionary({ type = type, value = parameters })
	# If the type is an instance of Injectable, create a new instance of the type.
	else:
		klass = _create_injectable(type, source, parameters)

	# If the type is not an instance of Injectable, InjectionToken, or String, return null.
	if !is_instance_of(klass, Injectable) and !is_instance_of(type, InjectionToken) and !(type is String):
		printerr('Injectable.provide: "type" must be an instance of Injectable, InjectionToken, or String.')
		return null

	# Get the current injectables on the node.
	var meta: Array = source.get_meta(META_NAME, [])
	meta.push_back(klass)
	source.set_meta(META_NAME, meta)

	# If the source is a node, set up a signal to clear the source injectable info.
	if source is Node:
		source.tree_exiting.connect(func(): clear(source))

	# Add the source node to the list of nodes with injectables if it isn't already in the list.
	if !nodes_with_injectables.has(source):
		nodes_with_injectables.push_back(source)

	# If the type is an InjectionToken, return the value.
	if klass is Dictionary and (klass.type is InjectionToken or klass.type is String):
		return klass.value
	# Otherwise, return the injectable.
	return klass


## Gets an injectable or a node.
## [b]Note:[/b] It is not advised to use this function in [_process] or [_physics_process].
## * [type] &ndash; is the injectable class to inject into the node.
## * [source] &ndash; is the node to start looking for the injectable. This usually is set to [self].
## * [multi] &ndash; is a boolean that determines if multiple injectables should be returned. This climbs all the way to the top of the node tree and returns an array of all the injectables that were found.
func inject(type: Variant, source: Variant = 'root', multi = false) -> Variant:
	return _find_injectable(type, source, multi)


## Clears one or all nodes of their injectables.
## Nodes referencing the injectables will start to return null.
## You can call `Injector.clear('all')` before you change scenes to clear all injectables.
## * [source] &ndash; is the node to clear the injectables from. Defaults to 'all' which clears all nodes.
## 		* If [source] &ndash; is 'root', it will clear the injectables from the root node.
##		* If [source] &ndash; is 'all', it will clear the injectables from all nodes.
##		* If [source] &ndash; is a node, it will clear the injectables from that node.
## * [protect] &ndash; is an array of nodes to protect from being cleared. This is useful if you want to clear all injectables from a node and it's children but want to protect a few nodes from being cleared.
func clear(source: Variant = 'all', protect: Array = []) -> void:
	if source is String and source == 'root':
		source = get_tree().root
	if source is String and source == 'all':
		for node in nodes_with_injectables:
			var meta = node.get_meta(META_NAME, [])
			if !protect.has(node):
				for injectable in meta:
					_clear_injectable(injectable)
				nodes_with_injectables.erase(node)
				node.set_meta(META_NAME, [])
	else:
		if nodes_with_injectables.has(source):
			for node in nodes_with_injectables:
				if _is_descendant_of(node, source):
					var meta = node.get_meta(META_NAME, [])
					if !protect.has(node):
						for injectable in meta:
							_clear_injectable(injectable)
						nodes_with_injectables.erase(node)
						node.set_meta(META_NAME, [])


## Removes an injectable from a node.
## * [source] &ndash; is the node to remove the injectable from.
## * [injectable] &ndash; is the injectable to remove. This can be any valid injectable data type.
func remove(source: Node, injectable: Variant) -> void:
	if nodes_with_injectables.has(source):
		var meta = source.get_meta(META_NAME, [])
		for item in meta:
			if item is String and injectable is String and item == injectable:
				_clear_injectable(injectable)
				meta.erase(item)
			elif item is Dictionary and injectable is InjectionToken and item.type.token_name == injectable.token_name:
				_clear_injectable(injectable)
				meta.erase(item)
			elif is_instance_of(item, injectable):
				_clear_injectable(injectable)
				meta.erase(item)
		source.set_meta(META_NAME, meta)


## Finds an injectable and recursively climbs up the node tree until it finds it.
## * [type] &ndash; is the injectable to find. This can be any valid injectable data type.
## * [source] &ndash; is the node to start looking for the injectable. Defaults to 'root' which starts at the root node.
## * [multi] &ndash; is a boolean that determines if multiple injectables should be returned. This climbs all the way to the top of the node tree and returns an array of all the injectables that were found.
## * [multiple] &ndash; is an array that is used internally to store the injectables that were found if [multi] is true.
func _find_injectable(type: Variant, source: Variant, multi: bool, multiple: Array = []) -> Variant:
	if source is String and source == 'root':
		source = get_tree().root
	var meta: Array = source.get_meta(META_NAME, [])

	# Loop through the injectables on the node and check if they match the type.
	for injectable in meta:
		# If the injectable is a string, check if the type is a string and if they match.
		if type is String:
			if injectable is Dictionary and injectable.type is InjectionToken and injectable.type.token_name == type:
				if multi:
					multiple.push_back(injectable.value)
				else:
					return injectable.value
			elif injectable is Dictionary and injectable.type is String and injectable.type == type:
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


## Clears an injectable by setting it to null, the garbage collector will take care of the rest.
## * [injectable] &ndash; is the injectable to clear.
func _clear_injectable(injectable: Variant) -> void:
	if injectable is Dictionary:
		if injectable.type is InjectionToken:
			injectable.value = null
	else:
		injectable = null


## Checks if a node is a descendant of another node.
## * [node] &ndash; is the node to check.
## * [parent] &ndash; is the node to check if it is a parent of the node.
func _is_descendant_of(node: Node, parent: Node) -> bool:
	if node == parent:
		return true
	if node.get_parent() == null:
		return false
	return _is_descendant_of(node.get_parent(), parent)


## Clears all injectables when the scene is exited.
func _on_tree_exiting():
	clear('all')


func _create_injectable(type: Variant, source: Node, parameters: Variant = null) -> Injectable:
	var params = []
	if parameters is Array:
		params = parameters
	else:
		if parameters != null:
			params.push_back(parameters)
	var klass := type.callv('new', params) as Injectable
	if klass is Injectable:
		klass.node_ref = source
	return klass


func _is_injectable(type: Variant) -> bool:
	if is_instance_of(type, Injectable) or is_instance_of(type, InjectionToken) or type is String:
		return true
	return false
