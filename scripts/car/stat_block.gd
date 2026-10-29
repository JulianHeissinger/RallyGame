class_name StatBlock
extends RefCounted
## Computes effective car stats as base, then additive modifiers, then multiplicative
## modifiers, then damage multipliers. Recomputes only after `mark_dirty()`.

var base: Dictionary = {}
var additive: Dictionary = {}
var multiplicative: Dictionary = {}
var damage_multiplier: Dictionary = {}

var _effective: Dictionary = {}
var _dirty := true


func _init(base_stats: Dictionary = {}) -> void:
	base = base_stats


func mark_dirty() -> void:
	_dirty = true


func get_stat(stat_name: String) -> float:
	if _dirty:
		_recompute()
	return _effective.get(stat_name, 0.0)


func _recompute() -> void:
	_effective.clear()
	for stat_name: String in base:
		var value: float = base[stat_name] + additive.get(stat_name, 0.0)
		value *= multiplicative.get(stat_name, 1.0)
		value *= damage_multiplier.get(stat_name, 1.0)
		_effective[stat_name] = value
	_dirty = false
