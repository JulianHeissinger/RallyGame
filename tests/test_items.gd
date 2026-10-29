extends "res://tests/test_case.gd"


class CountingEffect extends ItemEffect:
	var activations := 0
	var events: Array[String] = []

	func on_activate(_car: Node, _data: Variant) -> bool:
		activations += 1
		return true

	func on_event(_car: Node, event: String, _data: Variant) -> void:
		events.append(event)


## Stand-in for `Car` with the parts item effects use.
class FakeCar extends Node:
	var stats: StatBlock
	var damage: CarDamage
	var items: ItemManager
	var drivetrain := Drivetrain.new()


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
	assert_eq(def.effect.events.count("drift"), 0, "no events while off")
	damage.apply_damage("brake_rl", 100.0)
	manager.on_event("drift")
	assert_almost_eq(stats.get_stat("tire_friction"), 2.0, 0.0001, "on once a brake breaks")
	assert_eq(def.effect.events.count("drift"), 1, "events while on")
	damage.condition["brake_rl"] = 100.0
	manager.update_conditions()
	assert_almost_eq(stats.get_stat("tire_friction"), 1.0, 0.0001, "off again after repair")
	_free_nodes()
	damage.free()


func test_data_items_change_their_stats() -> void:
	var base: Dictionary = load("res://data/cars/prototype.tres").stats
	# id -> {stat: expected effective value with one copy}
	var expected := {
		"rally_tyres": {"tire_friction": base["tire_friction"] * 1.1},
		"turbo_kit": {"max_torque": base["max_torque"] * 1.12},
		"roll_cage": {"lethal_impact_speed": base["lethal_impact_speed"] + 3.0},
		"glass_cannon": {"max_torque": base["max_torque"] * 1.3, "impact_damage": base["impact_damage"] * 1.5},
		"rally_brakes": {"brake_torque": base["brake_torque"] * 1.15},
		"short_gearbox": {"final_drive": base["final_drive"] * 1.08},
		"stiff_springs": {"spring_stiffness": base["spring_stiffness"] * 1.15, "damper": base["damper"] * 1.15},
		"lightweight_panels": {"mass": base["mass"] * 0.93, "impact_damage": base["impact_damage"] * 1.1},
		"mechanics_tape": {"wear_rate": base["wear_rate"] * 0.75},
		"wide_steering_rack": {"max_steer_angle_deg": base["max_steer_angle_deg"] + 5.0,
			"min_steer_angle_deg": base["min_steer_angle_deg"] + 2.0},
		"cold_air_intake": {"max_torque": base["max_torque"] * 1.05},
		"sport_exhaust": {"max_torque": base["max_torque"] * 1.06, "redline_rpm": base["redline_rpm"] + 250.0},
		"chip_tune": {"redline_rpm": base["redline_rpm"] + 500.0, "shift_up_rpm": base["shift_up_rpm"] + 500.0},
		"lightweight_flywheel": {"shift_time": base["shift_time"] * 0.7,
			"engine_brake_torque": base["engine_brake_torque"] * 1.3},
		"armoured_sump": {"engine_damage_taken": 0.7},
		"kevlar_tyres": {"tire_damage_taken": 0.7},
		"forged_internals": {"engine_damage_taken": 0.75,
			"engine_damaged_power": base["engine_damaged_power"] + 0.15},
		"mud_flaps": {"patch_drag_scale": 0.5},
		"ice_studs": {"grip_snow": 1.25, "grip_ice": 1.25},
	}
	for id: String in expected:
		var stats := StatBlock.new(base)
		var manager := _manager(stats)
		var def: ItemDef = load("res://data/items/%s.tres" % id)
		assert_eq(def.id, id, "id matches file name")
		manager.add_item(def)
		for stat: String in expected[id]:
			assert_almost_eq(stats.get_stat(stat), expected[id][stat], 0.0001, "%s %s" % [id, stat])
		_free_nodes()


func test_damage_taken_scales_part_damage() -> void:
	var stats := StatBlock.new(load("res://data/cars/prototype.tres").stats)
	var damage := CarDamage.new()
	damage.stats = stats
	var manager := _manager(stats, damage)
	manager.add_item(load("res://data/items/kevlar_tyres.tres"))
	damage.apply_damage("tire_fl", 10.0)
	damage.apply_damage("brake_fl", 10.0)
	assert_almost_eq(damage.condition["tire_fl"], 93.0, 0.0001, "Kevlar Tyres take 30% less tire damage")
	assert_almost_eq(damage.condition["brake_fl"], 90.0, 0.0001, "other groups unchanged")
	_free_nodes()
	damage.free()


func test_repair_raises_condition_and_flips_condition() -> void:
	var stats := StatBlock.new({"tire_friction": 1.0})
	var damage := CarDamage.new()
	var manager := _manager(stats, damage)
	manager.add_item(_passive("drift_king", "tire_friction", 2.0, "brake"))
	damage.apply_damage("brake_fl", 100.0)
	assert_almost_eq(stats.get_stat("tire_friction"), 2.0, 0.0001, "on with a broken brake")
	damage.repair("brake_fl", 150.0)
	assert_almost_eq(damage.condition["brake_fl"], 100.0, 0.0001, "repair caps at 100")
	assert_almost_eq(stats.get_stat("tire_friction"), 1.0, 0.0001, "repair turns the condition off")
	damage.apply_damage("tire_fl", 50.0)
	damage.repair("tire_fl", 30.0)
	assert_almost_eq(damage.condition["tire_fl"], 50.0, 0.0001, "repair never lowers a condition")
	_free_nodes()
	damage.free()


func test_boost_meter_caps_and_refuses_overspend() -> void:
	var manager := _manager()
	manager.fill_boost(0.7)
	manager.fill_boost(0.7)
	assert_almost_eq(manager.boost, 1.0, 0.0001, "fill caps at 1")
	assert_true(manager.spend_boost(0.6), "spend with enough boost")
	assert_false(manager.spend_boost(0.6), "spend refused without enough boost")
	assert_almost_eq(manager.boost, 0.4, 0.0001, "refused spend takes nothing")
	_free_nodes()


func _fake_car() -> FakeCar:
	var car := FakeCar.new()
	car.stats = StatBlock.new(load("res://data/cars/prototype.tres").stats)
	car.damage = CarDamage.new()
	car.damage.stats = car.stats
	car.items = ItemManager.new()
	car.items.setup(car, car.stats, car.damage)
	_nodes.append_array([car, car.damage, car.items])
	return car


func test_drift_king_fills_boost_and_doubles_with_broken_brake() -> void:
	var car := _fake_car()
	car.items.add_item(load("res://data/items/drift_king.tres"))
	car.items.on_event("drift", {"delta": 1.0, "slip_deg": 20.0})
	assert_almost_eq(car.items.boost, 0.15, 0.0001, "one second of drift")
	car.items.on_event("jump")
	assert_almost_eq(car.items.boost, 0.15, 0.0001, "other events do not fill")
	car.damage.apply_damage("brake_fr", 100.0)
	car.items.on_event("drift", {"delta": 1.0, "slip_deg": 20.0})
	assert_almost_eq(car.items.boost, 0.45, 0.0001, "twice as fast with a broken brake")
	car.items.add_item(load("res://data/items/drift_king.tres"))
	car.items.on_event("drift", {"delta": 1.0, "slip_deg": 20.0})
	assert_almost_eq(car.items.boost, 1.0, 0.0001, "two copies fill twice, capped at 1")
	_free_nodes()


func test_gearbox_of_chaos_lands_in_another_gear_and_holds() -> void:
	var car := _fake_car()
	car.items.add_item(load("res://data/items/gearbox_of_chaos.tres"))
	assert_almost_eq(car.stats.get_stat("max_torque"), car.stats.base["max_torque"] * 1.25, 0.0001, "power bonus")
	var gearbox := car.drivetrain.gearbox
	for i in 20:
		gearbox.gear = 2
		gearbox.gear_shifted.emit(1, 2)
		car.items.on_event("gear_shift", {"from": 1, "to": 2})
		assert_true(gearbox.gear != 2 and gearbox.gear >= 1 and gearbox.gear <= 5, "random other forward gear, got %d" % gearbox.gear)
	car.items.on_event("gear_shift", {"from": 1, "to": Gearbox.NEUTRAL})
	assert_true(gearbox.gear >= 1, "shifts into neutral are left alone")
	# Automatic mode wants 2nd at this speed; the forced 1st holds for 1.5 s.
	gearbox.force_gear(1, 1.5)
	var input := InputSource.new()
	var speed := 30.0
	var spin := speed / car.stats.get_stat("wheel_radius")
	for i in 168:
		gearbox.update(input, spin, speed, car.stats, 1.0 / 120.0)
	assert_eq(gearbox.gear, 1, "held for 1.4 s")
	for i in 120:
		gearbox.update(input, spin, speed, car.stats, 1.0 / 120.0)
	assert_true(gearbox.gear > 1, "shifts again after the hold")
	_free_nodes()


func test_underdog_adds_power_per_broken_part() -> void:
	var car := _fake_car()
	var base: float = car.stats.base["max_torque"]
	car.items.add_item(load("res://data/items/underdog.tres"))
	assert_almost_eq(car.stats.get_stat("max_torque"), base, 0.0001, "no broken parts")
	car.damage.apply_damage("tire_fl", 100.0)
	car.damage.apply_damage("brake_rr", 100.0)
	assert_almost_eq(car.stats.get_stat("max_torque"), base * 1.1, 0.0001, "two broken parts")
	car.damage.repair("brake_rr", 50.0)
	assert_almost_eq(car.stats.get_stat("max_torque"), base * 1.05, 0.0001, "repair removes the bonus")
	_free_nodes()


func test_lucky_dice_repairs_and_prevents_immobilization() -> void:
	var car := _fake_car()
	var dice: ItemDef = load("res://data/items/lucky_dice.tres").duplicate(true)
	dice.effect.chance = 1.0
	car.items.add_item(dice)
	car.damage.apply_damage("engine", 100.0)
	assert_almost_eq(car.damage.condition["engine"], 30.0, 0.0001, "broken engine repaired to 30")
	assert_false(car.damage.is_immobilized, "repaired before the immobilize check")
	dice.effect.chance = 0.0
	car.damage.apply_damage("engine", 100.0)
	assert_true(car.damage.is_immobilized, "no repair on a failed roll")
	_free_nodes()


func test_overboost_doubles_engine_damage() -> void:
	var car := _fake_car()
	car.items.add_item(load("res://data/items/overboost.tres"))
	assert_true(load("res://data/items/overboost.tres").cursed, "marked cursed")
	assert_almost_eq(car.stats.get_stat("max_torque"), car.stats.base["max_torque"] * 1.35, 0.0001, "power bonus")
	car.damage.apply_damage("engine", 10.0)
	assert_almost_eq(car.damage.condition["engine"], 80.0, 0.0001, "double engine damage")
	_free_nodes()


class RefusingEffect extends ItemEffect:
	var refuse := true

	func on_activate(_car: Node, _data: Variant) -> bool:
		return not refuse


func test_failed_activation_starts_no_cooldown() -> void:
	var manager := _manager()
	var def := _active("jacks", ItemDef.Mount.TRUNK, ItemDef.Activation.BUTTON, 6.0)
	def.effect = RefusingEffect.new()
	manager.add_item(def)
	manager.activate_button()
	assert_almost_eq(manager.cooldowns[ItemDef.Mount.TRUNK], 0.0, 0.0001, "refused: no cooldown")
	def.effect.refuse = false
	manager.activate_button()
	assert_almost_eq(manager.cooldowns[ItemDef.Mount.TRUNK], 6.0, 0.0001, "fired: cooldown starts")
	_free_nodes()


func test_bullbar_halves_front_impact_damage() -> void:
	var car := _fake_car()
	car.damage.apply_impact(car.stats, Vector3(0.8, 0.0, -1.9), 13.0, false)
	var bare: float = 100.0 - car.damage.condition["tire_fr"]
	var rear_bare: float = 100.0 - car.damage.condition["tire_rr"]
	var armoured := _fake_car()
	armoured.items.add_item(load("res://data/items/bullbar.tres"))
	armoured.damage.apply_impact(armoured.stats, Vector3(0.8, 0.0, -1.9), 13.0, false)
	assert_true(bare > 0.0, "bare front hit damages the tire")
	assert_almost_eq(100.0 - armoured.damage.condition["tire_fr"], bare * 0.5, 0.0001, "bullbar halves front damage")
	armoured.damage.apply_impact(armoured.stats, Vector3(0.8, 0.0, 1.9), 13.0, false)
	car.damage.apply_impact(car.stats, Vector3(0.8, 0.0, 1.9), 13.0, false)
	assert_almost_eq(armoured.damage.condition["tire_rr"], car.damage.condition["tire_rr"], 0.0001, "rear hits unchanged")
	assert_almost_eq(rear_bare, 0.0, 0.0001, "front hit left the rear alone")
	_free_nodes()


func test_spare_wheel_repairs_a_broken_tire_only() -> void:
	var car := _fake_car()
	car.items.add_item(load("res://data/items/spare_wheel.tres"))
	car.damage.apply_damage("brake_fl", 100.0)
	assert_almost_eq(car.damage.condition["brake_fl"], 0.0, 0.0001, "other parts stay broken")
	assert_almost_eq(car.items.cooldowns[ItemDef.Mount.TRUNK], 0.0, 0.0001, "no cooldown on other parts")
	car.damage.apply_damage("tire_rl", 100.0)
	assert_almost_eq(car.damage.condition["tire_rl"], 60.0, 0.0001, "broken tire back to 60")
	assert_almost_eq(car.items.cooldowns[ItemDef.Mount.TRUNK], 60.0, 0.0001, "cooldown starts")
	car.damage.apply_damage("tire_fr", 100.0)
	assert_almost_eq(car.damage.condition["tire_fr"], 0.0, 0.0001, "no spare during cooldown")
	_free_nodes()


func test_roll_hoop_cancels_the_rollover_penalty() -> void:
	var car := _fake_car()
	car.items.add_item(load("res://data/items/roll_hoop.tres"))
	var data := {"penalty": 5.0}
	car.items.on_event("rolled_over", data)
	assert_almost_eq(data["penalty"], 0.0, 0.0001, "penalty cancelled")
	data = {"penalty": 5.0}
	car.items.on_event("rolled_over", data)
	assert_almost_eq(data["penalty"], 5.0, 0.0001, "full penalty during cooldown")
	_free_nodes()
