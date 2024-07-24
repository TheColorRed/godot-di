- [Introduction to Services and Dependency Injection](#introduction-to-services-and-dependency-injection)
- [Godot Dependency Injection](#godot-dependency-injection)
  - [Usage](#usage)
    - [Injectable](#injectable)
    - [InjectionToken](#injectiontoken)
  - [API](#api)
    - [Injectable](#injectable-1)
      - [Injectable.provide](#injectableprovide)
      - [Injectable.inject](#injectableinject)
    - [InjectionToken](#injectiontoken-1)
  - [Included Services](#included-services)
    - [Game Ref](#game-ref)
      - [Usage](#usage-1)
    - [Node Ref](#node-ref)
      - [Usage](#usage-2)

# Introduction to Services and Dependency Injection

_Service_ is a broad category encompassing any value, function, or feature that an games needs. A service is typically a class with a narrow, well-defined purpose. It should do something specific and do it well.

Ideally, a scene scripts's job is to enable only the user experience. A scene script should present properties and methods for data binding to mediate between the view and the game logic. The view is what the scene renders and the game logic is what includes the notion of a model.

A scene script should use services for tasks that don't involve the scene or scene script logic. Services are good for tasks such as fetching data from the server, validating user input, or logging directly to the console. By defining such processing tasks in an injectable service class, you make those tasks available to any component. You can also make your game more adaptable by injecting different providers of the same kind of service, as appropriate in different circumstances.

# Godot Dependency Injection

This is a simple dependency injection system for Godot. It is designed to be simple to use and easy to understand.

1. Add the `injector.gd` script to your autoloads.
2. Provide a class or value to the injector.
3. Inject the class or value from the injector.

Once you provide a value to a node, it and all of it's children will have access to it!

```php
# A class to hold the stats of a player or enemy.
class_name Stats extends Injectable

var health := 100
var attack := 100

func receive_damage(damage: int):
  health -= damage
```

```php
# player.gd
@onready var player_stats: Stats = Injector.inject(Stats)

func _enter_tree():
  Injector.provide(Stats)

func _process():
  if player_stats.health <= 0:
    print("Game Over!")
    get_tree().reload_current_scene()
```

```php
# enemy.gd
@exports var attack_box: Area2D

@onready var player_stats: Stats = Injector.inject(Stats)
@onready var enemy_stats: Stats = Injector.inject(Stats, self)

func _enter_tree():
  Injector.provide(Stats, self)

func _ready():
  attack_box.area_entered.connect(_on_attack_box_area_entered)

func _on_attack_box_area_entered(area: Area2D):
  player_stats.receive_damage(enemy_stats.attack)
```

## Usage

There are two types of dependencies: Injectable and InjectionToken.

- Injectable: A class that will be created by the injector.
- InjectionToken: A token that can be used to inject a value.

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
var my_injectable := Injectable.provide(MyInjectable, self, 1)

# Option 2:
func _enter_tree():
  Injectable.provide(MyInjectable, self, 1)
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

Another way is to use an `InjectionToken`. This is useful if you want to inject a value that is not a class that extends `Injectable`. An injection token can be either a `string` or or an instance of `InjectionToken`.

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
var my_token := Injectable.provide(Tokens.MyToken, self, bullets)

# Option 2:
func _enter_tree():
  Injectable.provide(Tokens.MyToken, self, bullets)
```

Lastly we get the value on a child node that we want to use this for (this can be at any depth, as it does not have to be a direct child). This can be done in the `_ready` function or with `@onready`

```php
# Option 1:
@onready var bullets: Node2D = Injectable.inject(Tokens.MyToken, self)

# Option 2:
func _ready():
  var bullets: Node2D = Injectable.inject(Tokens.MyToken, self)

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

#### Injectable.provide

This function registers an `Injectable` or `InjectionToken` with the injector.

**Returns:** The `Injectable` instance or `InjectionToken` value that was registered with the injector. If nothing was registered, `null` is returned (this often happens when the wrong type is passed in).

| Argument     | Type                             | Description                                                                                                                                                   | Required |
| ------------ | -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| `type`       | `Injectable` or `InjectionToken` | The type of the injectable.                                                                                                                                   | `true`   |
| `source`     | `Node` or `"root"`               | The node in which to start the search up the tree. Defaults to `"root"`.                                                                                      | `false   |
| `parameters` | `Array` or `Variant`             | An array of parameters to pass to the `Injectable` (an array is only needed for 2 or more parameters) or a value for an `InjectionToken`. Defaults to `null`. | `false`  |

```php
# Injectable
Injectable.provide(MyInjectable1, self, [1, 2, 3])
Injectable.provide(MyInjectable2, self, "Example")

# InjectionToken
Injectable.provide(Tokens.MyToken1, self, 1)
Injectable.provide(Tokens.MyToken2, self, node_ref)

# String
Injectable.provide("custom_string", self)
Injectable.provide("custom_string", self, "Example")
```

#### Injectable.inject

This function finds the `Injectable` or `InjectionToken` that was registered with the injector somewhere up the tree.

**Returns:** The `Injectable` or `InjectionToken` that was registered with the injector. If nothing was found, `null` is returned.

| Argument | Type                             | Description                                                                       | Required |
| -------- | -------------------------------- | --------------------------------------------------------------------------------- | -------- |
| `type`   | `Injectable` or `InjectionToken` | The type of the injectable.                                                       | `true`   |
| `source` | `Node` or `"root"`               | The node in which to start the search up the tree. Defaults to `"root"`.          | `false`  |
| `multi`  | `bool`                           | If true, an array of all injectables found will be returned. Defaults to `false`. | `false`  |

```php
# Injectable
@onready var my_injectable1: MyInjectable1 = Injectable.inject(MyInjectable1, self)
@onready var array: Array = Injectable.inject(MyInjectable1, self, true)

# InjectionToken
@onready var my_token1: Node2D = Injectable.inject(Tokens.MyToken1, self)
@onready var my_token2: int = Injectable.inject(Tokens.MyToken2, self)
@onready var array: Array = Injectable.inject(Tokens.MyToken1, self, true)

# String
@onready var custom_string = Injectable.inject("custom_string", self)
```

### InjectionToken

An `InjectionToken` is a token that can be used to create a value that is not a class that extends `Injectable`. Such as a `Node`, `int`, `Array`, etc. It is defined by creating a new instance of the `InjectionToken` class.

| Argument | Type     | Description            | Required |
| -------- | -------- | ---------------------- | -------- |
| `name`   | `String` | The name of the token. | `true`   |

These tokens can be placed where ever you see fit. An `Autoload` script is a good place to put them for access throughout the project. They can also be placed in a node as a `static var`.

**Hint:** Postfixing `Token` to the variable name is a good way to keep track of these.

```php
# tokens.gd (Autoload as Tokens)
var MyToken = InjectionToken.new("MyToken")

# MyNode.gd (as a static var)
static var MyToken = InjectionToken.new("MyToken")
```

## Included Services

### Game Ref

This service provides a reference to the `Window` or to the `SceneTree` depending on what you would like.

#### Usage

```php
@onready var game_ref: GameRef = Injector.inject(GameRef)

func _ready():
  print(game_ref.root)
  print(game_ref.tree)
```

### Node Ref

This service provides a reference to a node in the scene tree.

#### Usage

```php
# enemy.gd
class_name Enemy extends Area2D

func _enter_tree():
  Injector.provide(NodeRef, self, self)
```

```php
# player.gd
class_name Player extends Node2D

func _on_enemy_entered(area: Area2D):
  var enemy = Injector.inject(NodeRef, area)
  self.queue_free()
```
