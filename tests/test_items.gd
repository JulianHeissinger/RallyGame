extends "res://tests/test_case.gd"


class CountingEffect extends ItemEffect:
	var activations := 0
	var events: Array[String] = []

	func on_activate(_car: Node) -> void:
		activations += 1

	func on_event(_car: Node, event: String, _data: Variant) -> void:
		events.append(event)


## Nodes made by a test, freed by `_free_nodes()` at its end.
var _nodes: Array[Node] = []


func _manager(stats: StatBlock = StatBlock.new({"tire_friction": 1.0}), damage: CarDamage = null) -> ItemManager:
	if damage == null:
		damage = CarDamage.new()
		_nodes.append(damage)
	var manager := ItemManager.new()
	_nodes.append(manager)
	manager.setup(null, stats, damage)
	return manager


func _free_nodes() -> void:
	for node in _nodes:
		node.free()
	_nodes.clear()


func _passive(id: String, stat: String, multiplier: float, condition := "") -> ItemDef:
	var modifier := StatModifier.new()
	modifier.stat = stat
	modifier.multiplier = multiplier
	var def := ItemDef.new()
	def.id = id
	def.modifiers = [modifier]
	def.condition_broken = condition
	return def


func _active(id: String, mount: ItemDef.Mount, activation: ItemDef.Activation, cooldown := 0.0) -> ItemDef:
	var def := ItemDef.new()
	def.id = id
	def.kind = ItemDef.Kind.ACTIVE
	def.mount = mount
	def.activation = activation
	def.cooldown = cooldown
	def.effect = CountingEffect.new()
	return def


func test_passive_copies_stack() -> void:
	var stats := StatBlock.new({"tire_friction": 1.0})
	var manager := _manager(stats)
	var grip := _passive("grip", "tire_friction", 1.1)
	manager.add_item(grip)
	assert_almost_eq(stats.get_stat("tire_friction"), 1.1, 0.0001, "one copy")
	manager.add_item(grip)
	assert_almost_eq(stats.get_stat("tire_friction"), 1.21, 0.0001, "two copies multiply")
	assert_eq(manager.passives["grip"]["count"], 2, "stack count")
	_free_nodes()


func test_additive_copies_stack() -> void:
	var stats := StatBlock.new({"lethal_impact_speed": 20.0})
	var manager := _manager(stats)
	var def := _passive("tough", "lethal_impact_speed", 1.0)
	def.modifiers[0].additive = 3.0
	manager.add_item(def)
	manager.add_item(def)
	assert_almost_eq(stats.get_stat("lethal_impact_speed"), 26.0, 0.0001, "two copies add up")
	_free_nodes()


func test_mount_replaces_old_item() -> void:
	var manager := _manager()
	var old := _active("old", ItemDef.Mount.FRONT_BUMPER, ItemDef.Activation.BUTTON)
	var new := _active("new", ItemDef.Mount.FRONT_BUMPER, ItemDef.Activation.BUTTON)
	var roof := _active("roof", ItemDef.Mount.ROOF, ItemDef.Activation.BUTTON)
	manager.add_item(old)
	manager.add_item(roof)
	manager.add_item(new)
	assert_eq(manager.mounts[ItemDef.Mount.FRONT_BUMPER], new, "new item in the slot")
	assert_eq(manager.mounts[ItemDef.Mount.ROOF], roof, "other slot untouched")
	manager.activate_button()
	assert_eq(old.effect.activations, 0, "replaced item no longer fires")
	assert_eq(new.effect.activations, 1, "new item fires")
	_free_nodes()


func test_cooldown_blocks_activation() -> void:
	var manager := _manager()
	var nitro := _active("nitro", ItemDef.Mount.TRUNK, ItemDef.Activation.BUTTON, 5.0)
	manager.add_item(nitro)
	manager.activate_button()
	manager.activate_button()
	assert_eq(nitro.effect.activations, 1, "second press on cooldown does nothing")
	manager._physics_process(5.0)
	manager.activate_button()
	assert_eq(nitro.effect.activations, 2, "fires again after the cooldown")
	_free_nodes()


func test_trigger_fires_on_event_and_respects_cooldown() -> void:
	var manager := _manager()
	var exhaust := _active("exhaust", ItemDef.Mount.REAR, ItemDef.Activation.TRIGGER, 1.0)
	exhaust.trigger_event = "gear_shift"
	manager.add_item(exhaust)
	manager.on_event("jump")
	assert_eq(exhaust.effect.activations, 0, "other events do not trigger")
	manager.on_event("gear_shift")
	manager.on_event("gear_shift")
	assert_eq(exhaust.effect.activations, 1, "trigger on cooldown does nothing")
	manager.activate_button()
	assert_eq(exhaust.effect.activations, 1, "button does not fire trigger items")
	assert_eq(exhaust.effect.events, ["jump", "gear_shift", "gear_shift"], "effect receives every event")
	_free_nodes()


func test_condition_toggles_on_break_and_repair() -> void:
	var stats := StatBlock.new({"tire_friction": 1.0})
	var damage := CarDamage.new()
	var manager := _manager(stats, damage)
	var def := _passive("drift_king", "tire_friction", 2.0, "brake")
	def.effect = CountingEffect.new()
	manager.add_item(def)
	manager.on_event("drift")
	assert_almost_eq(stats.get_stat("tire_friction"), 1.0, 0.0001, "off with intact brakes")
	assert_eq(def.effect.events.size(), 0, "no events while off")
	damage.apply_damage("brake_rl", 100.0)
	manager.on_event("drift")
	assert_almost_eq(stats.get_stat("tire_friction"), 2.0, 0.0001, "on once a brake breaks")
	assert_eq(def.effect.events.size(), 1, "events while on")
	damage.condition["brake_rl"] = 100.0
	manager.update_conditions()
	assert_almost_eq(stats.get_stat("tire_friction"), 1.0, 0.0001, "off again after repair")
	_free_nodes()
	damage.free()
