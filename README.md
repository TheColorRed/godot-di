- [Godot Dependency Injection](#godot-dependency-injection)
  - [Usage](#usage)
    - [Injectable](#injectable)
    - [InjectionToken](#injectiontoken)
  - [API](#api)
    - [Injectable](#injectable-1)
      - [Injectable.provides](#injectableprovides)
      - [Injectable.inject](#injectableinject)
    - [InjectionToken](#injectiontoken-1)

# Godot Dependency Injection

This is a simple dependency injection system for Godot. It is designed to be simple to use and easy to understand.

## Usage

There are two types of dependencies: Injectable and InjectionToken.
* Injectable: A class that will be created by the injector.
* InjectionToken: A token that can be used to inject a value.

### Injectable

To make a class injectable, simply extend the `Injectable` class.

```php
class_name MyInjectable extends Injectable

var my_value := 0

func _init(v: int):
  my_value = v
```

Next, we register the injectable with the injector on a specific node. It is best to do this as a `variable` or in the `_enter_tree` function. If you do it in the `_ready` function child nodes may try to access this too soon.

```php
# Option 1:
var my_injectable := Injectable.provides(MyInjectable, self, 1)

# Option 2:
func _enter_tree():
  Injectable.provides(MyInjectable, self, 1)
```

Lastly we get the value on a child node that we want to use this for (this can be at any depth, as it does not have to be a direct child). This can be done in the `_ready` function or with `@onready`.

```php
# Option 1:
@onready var my_injectable: MyInjectable = Injectable.inject(MyInjectable, self)

# Option 2:
func _ready():
  var my_injectable: MyInjectable = Injectable.inject(MyInjectable, self)

  # After using option 1 or 2, we can now do this:
  print(my_injectable.my_value)
```

### InjectionToken

Another way is to use an `InjectionToken`. This is useful if you want to inject a value that is not a class that extends `Injectable`.

A good place to put these tokens is in an `Autoload` script. However, these could also be put in a node as a `static var`.

```php
# tokens.gd (Autoload as Tokens)
var MyToken := InjectionToken.new("MyToken")
```

Next, we register the token with the injector on a specific node. It is best to do this as a variable or in the `_enter_tree` function. If you do it in the `_ready` function child nodes may try to access this too soon.

```php
# Get a reference to the node that will hold the bullet nodes.
@export var bullets: Node2D

# Option 1:
var my_token := InjectionToken.provides(Tokens.MyToken, self, bullets)

# Option 2:
func _enter_tree():
  Injectable.provides(Tokens.MyToken, self, bullets)
```

Lastly we get the value on a child node that we want to use this for (this can be at any depth, as it does not have to be a direct child). This can be done in the `_ready` function or with `@onready`

```php
# Option 1:
@onready var bullets: Node2D = InjectionToken.inject(Tokens.MyToken, self)

# Option 2:
func _ready():
  var bullets: Node2D = InjectionToken.inject(Tokens.MyToken, self)

  # After using option 1 or 2, we can now do this:
  var bullet := preload("res://Bullet.tscn").instantiate()
  bullets.add_child(bullet)
```

## API

### Injectable

An `Injectable` is a class that will be created by the injector. It is defined by extending the `Injectable` class. This class can have an `_init` function that takes any number of arguments.

```php
class_name MyInjectable extends Injectable
```

#### Injectable.provides

This function registers an `Injectable` or `InjectionToken` with the injector.

**Returns:** The `Injectable` instance or `InjectionToken` value that was registered with the injector. If nothing was registered, `null` is returned (this often happens when the wrong type is passed in).

| Argument | Type | Description | Required |
| --- | --- | --- | --- |
| `type` | `Injectable` or `InjectionToken` | The type of the injectable. | `true` |
| `source` | `Node` | The node in which to start the search up the tree. | `true` |
| `parameters` | `Array` or `Variant` | An array of parameters to pass to the `Injectable` (an array is only needed for 2 or more parameters) or a value for an `InjectionToken`. Defaults to `null`. | `false` |

```php
# Injectable
Injectable.provides(MyInjectable1, self, [1, 2, 3])
Injectable.provides(MyInjectable2, self, "Example")

# InjectionToken
Injectable.provides(Tokens.MyToken1, self, 1)
Injectable.provides(Tokens.MyToken2, self, node_ref)
```

#### Injectable.inject

This function finds the `Injectable` or `InjectionToken` that was registered with the injector somewhere up the tree.

**Returns:** The `Injectable` or `InjectionToken` that was registered with the injector. If nothing was found, `null` is returned.

| Argument | Type | Description | Required |
| --- | --- | --- | --- |
| `type` | `Injectable` or `InjectionToken` | The type of the injectable. | `true` |
| `source` | `Node` | The node in which to start the search up the tree. | `true` |
| `multi` | `bool` | If true, an array of all injectables found will be returned. Defaults to `false`. | `false` |

```php
# Injectable
@onready var my_injectable1: MyInjectable1 = Injectable.inject(MyInjectable1, self)
@onready var array: Array = Injectable.inject(MyInjectable1, self, true)

# InjectionToken
@onready var my_token1: Node2D = Injectable.inject(Tokens.MyToken1, self)
@onready var my_token2: int = Injectable.inject(Tokens.MyToken2, self)
@onready var array: Array = Injectable.inject(Tokens.MyToken1, self, true)
```

### InjectionToken

An `InjectionToken` is a token that can be used to create a value that is not a class that extends `Injectable`. Such as a `Node`, `int`, `Array`, etc. It is defined by creating a new instance of the `InjectionToken` class.

| Argument | Type | Description | Required |
| --- | --- | --- | --- |
| `name` | `String` | The name of the token. | `true` |

These tokens can be placed where ever you see fit. An `Autoload` script is a good place to put them for access throughout the project. They can also be placed in a node as a `static var`.

**Hint:** Postfixing `Token` to the variable name is a good way to keep track of these.

```php
# tokens.gd (Autoload as Tokens)
var MyToken = InjectionToken.new("MyToken")

# MyNode.gd (as a static var)
static var MyToken = InjectionToken.new("MyToken")
```