## KarmaManager — Hidden Karma System
## Static helper class. No autoload needed.
## Usage:
##   KarmaManager.get_karma()         → int (-100..100)
##   KarmaManager.add_karma(10)       → adds with clamp
##   KarmaManager.get_tier()          → "saint"/"good"/"neutral"/"bad"/"evil"
##   KarmaManager.get_price_modifier()→ 0.75..1.25

class_name KarmaManager

const KARMA_MIN := -100
const KARMA_MAX := 100

## Get current karma value
static func get_karma() -> int:
	var v = Variables.get_variable("karma", 0)
	if v is float:
		return int(v)
	if v is String:
		return int(v) if v.is_valid_int() else 0
	return v

## Add or subtract karma, clamped to [-100, 100]
static func add_karma(amount: int) -> void:
	var current = get_karma()
	var new_val = clampi(current + amount, KARMA_MIN, KARMA_MAX)
	Variables.add_variable("karma", new_val)

## Set karma to an exact value
static func set_karma(value: int) -> void:
	Variables.add_variable("karma", clampi(value, KARMA_MIN, KARMA_MAX))

## Get the karma tier as a string
static func get_tier() -> String:
	var k = get_karma()
	if k >= 76: return "saint"
	if k >= 26: return "good"
	if k >= -25: return "neutral"
	if k >= -75: return "bad"
	return "evil"

## Get price modifier based on karma tier
## saint = 0.75 (25% discount), evil = 1.25 (25% markup)
static func get_price_modifier() -> float:
	match get_tier():
		"saint":   return 0.75
		"good":    return 0.90
		"neutral": return 1.00
		"bad":     return 1.10
		"evil":    return 1.25
	return 1.0

## Apply karma-based pricing to a base price
static func apply_price(base_price: int) -> int:
	return int(base_price * get_price_modifier())
