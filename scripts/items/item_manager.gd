class_name ItemManager
extends Node
## Items owned by one car: passive stacks and four mount slots. Writes item modifiers into the
## car's `StatBlock` and fans car and stage events out to item effects.

## Passive items by id: {"def": ItemDef, "count": int}.
var passives: Dictionary = {}
## Mounted active item per `ItemDef.Mount`, or absent.
var mounts: Dictionary = {}
## Seconds left per mount slot.
var cooldowns: Dictionary = {}
## Boost meter from 0 to 1 that items fill (drifting) and spend (nitro).
var boost := 0.0

var _car: Node
var _stats: StatBlock
var _damage: CarDamage
## Item ids whose condition was met at the last check.
var _active: Dictionary = {}


func setup(car: Node, stats: StatBlock, damage: CarDamage) -> void:
	_car = car
	_stats = stats
	_damage = damage
	# Recompute first, so effects see the new conditions; dynamic modifiers depend on parts too.
	_damage.part_broken.connect(func(part: String) -> void:
		_recompute()
		on_event("part_broken", {"part": part}))
	_damage.part_repaired.connect(func(_part: String) -> void: _recompute())
	_damage.part_damaged.connect(func(part: String, amount: float) -> void:
		on_event("part_damaged", {"part": part, "amount": amount}))
	_recompute()


func _physics_process(delta: float) -> void:
	for slot: int in cooldowns:
		cooldowns[slot] = maxf(cooldowns[slot] - delta, 0.0)
	for def in _all_items():
		if def.effect and _active.has(def.id):
			for i in _count(def):
				def.effect.on_physics(_car, delta)


## Passive items add a stack; active items replace whatever is in their mount slot.
func add_item(def: ItemDef) -> void:
	if def.kind == ItemDef.Kind.PASSIVE:
		if passives.has(def.id):
			passives[def.id]["count"] += 1
		else:
			passives[def.id] = {"def": def, "count": 1}
	else:
		mounts[def.mount] = def
		cooldowns[def.mount] = 0.0
	_recompute()


## Re-checks broken-part conditions and recomputes stats when one flips. For condition changes
## outside `part_broken` and `part_repaired`, which recompute anyway.
func update_conditions() -> void:
	for def in _all_items():
		if _condition_met(def) != _active.has(def.id):
			_recompute()
			return


func fill_boost(amount: float) -> void:
	boost = minf(boost + amount, 1.0)


## Spends `amount` of boost. Returns false and spends nothing when there is not enough.
func spend_boost(amount: float) -> bool:
	if boost < amount:
		return false
	boost -= amount
	return true


## Fires every ready BUTTON item.
func activate_button() -> void:
	for slot: int in mounts:
		var def: ItemDef = mounts[slot]
		if def.activation == ItemDef.Activation.BUTTON:
			_fire(slot, null)


## Passes `event` to the effects of items whose condition is met, once per owned copy, and fires
## ready TRIGGER items listening for it.
func on_event(event: String, data: Variant = null) -> void:
	for def in _all_items():
		if def.effect and _active.has(def.id):
			for i in _count(def):
				def.effect.on_event(_car, event, data)
	for slot: int in mounts:
		var def: ItemDef = mounts[slot]
		if def.activation == ItemDef.Activation.TRIGGER and def.trigger_event == event:
			_fire(slot, data)


## Fires a ready item; the cooldown starts only if its effect fired.
func _fire(slot: int, data: Variant) -> void:
	var def: ItemDef = mounts[slot]
	if cooldowns[slot] > 0.0 or not _active.has(def.id):
		return
	if def.effect == null or def.effect.on_activate(_car, data):
		cooldowns[slot] = def.cooldown


func _all_items() -> Array[ItemDef]:
	var items: Array[ItemDef] = []
	for entry: Dictionary in passives.values():
		items.append(entry["def"])
	for def: ItemDef in mounts.values():
		items.append(def)
	return items


## Owned copies: the passive stack size, or 1 for a mounted item.
func _count(def: ItemDef) -> int:
	return passives[def.id]["count"] if passives.has(def.id) else 1


func _condition_met(def: ItemDef) -> bool:
	if def.condition_broken.is_empty():
		return true
	for part: String in _damage.condition:
		if (part == def.condition_broken or part.begins_with(def.condition_broken + "_")) \
				and _damage.condition[part] <= 0.0:
			return true
	return false


## Rebuilds the additive and multiplicative item modifiers, static and from effects, from scratch.
func _recompute() -> void:
	_active.clear()
	_stats.additive.clear()
	_stats.multiplicative.clear()
	for def in _all_items():
		if not _condition_met(def):
			continue
		_active[def.id] = true
		var count := _count(def)
		var modifiers := def.modifiers.duplicate()
		if def.effect:
			modifiers.append_array(def.effect.dynamic_modifiers(_car))
		for modifier: StatModifier in modifiers:
			_stats.additive[modifier.stat] = _stats.additive.get(modifier.stat, 0.0) + modifier.additive * count
			_stats.multiplicative[modifier.stat] = _stats.multiplicative.get(modifier.stat, 1.0) * pow(modifier.multiplier, count)
	_stats.mark_dirty()
