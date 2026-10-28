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
	_damage.part_broken.connect(func(_part: String) -> void: update_conditions())
	_damage.part_repaired.connect(func(_part: String) -> void: update_conditions())
	_recompute()


func _physics_process(delta: float) -> void:
	for slot: int in cooldowns:
		cooldowns[slot] = maxf(cooldowns[slot] - delta, 0.0)


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


## Re-checks broken-part conditions and recomputes stats when one flips. Runs on `part_broken`
## and `part_repaired`.
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
			_fire(slot)


## Passes `event` to the effects of items whose condition is met, and fires ready TRIGGER items
## listening for it.
func on_event(event: String, data: Variant = null) -> void:
	for def in _all_items():
		if def.effect and _active.has(def.id):
			def.effect.on_event(_car, event, data)
	for slot: int in mounts:
		var def: ItemDef = mounts[slot]
		if def.activation == ItemDef.Activation.TRIGGER and def.trigger_event == event:
			_fire(slot)


func _fire(slot: int) -> void:
	var def: ItemDef = mounts[slot]
	if cooldowns[slot] > 0.0 or not _active.has(def.id):
		return
	cooldowns[slot] = def.cooldown
	if def.effect:
		def.effect.on_activate(_car)


func _all_items() -> Array[ItemDef]:
	var items: Array[ItemDef] = []
	for entry: Dictionary in passives.values():
		items.append(entry["def"])
	for def: ItemDef in mounts.values():
		items.append(def)
	return items


func _condition_met(def: ItemDef) -> bool:
	if def.condition_broken.is_empty():
		return true
	for part: String in _damage.condition:
		if (part == def.condition_broken or part.begins_with(def.condition_broken + "_")) \
				and _damage.condition[part] <= 0.0:
			return true
	return false


## Rebuilds the additive and multiplicative item modifiers from scratch.
func _recompute() -> void:
	_active.clear()
	_stats.additive.clear()
	_stats.multiplicative.clear()
	for def in _all_items():
		if not _condition_met(def):
			continue
		_active[def.id] = true
		var count: int = passives[def.id]["count"] if passives.has(def.id) else 1
		for modifier in def.modifiers:
			_stats.additive[modifier.stat] = _stats.additive.get(modifier.stat, 0.0) + modifier.additive * count
			_stats.multiplicative[modifier.stat] = _stats.multiplicative.get(modifier.stat, 1.0) * pow(modifier.multiplier, count)
	_stats.mark_dirty()
