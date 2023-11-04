## A service that maintains a single number.
## This value can represent any type of number data, such as a score, health, etc.
class_name NumberService extends Injectable

## The current number.
var _number: Variant = 0


## Returns the current number.
func get_number() -> Variant:
	return _number


## Sets the number to the given number.
func set_number(p_amount: Variant):
	if _is_number(p_amount):
		_number = p_amount


## Adjusts the number by the given amount.
## If the amount is positive, the number is increased.
## If the amount is negative, the number is decreased.
func adjust_number(p_amount: Variant):
	if _is_number(p_amount):
		_number += p_amount


## Returns true if the given value is a number.
func _is_number(value: Variant) -> bool:
	return value is int or value is float