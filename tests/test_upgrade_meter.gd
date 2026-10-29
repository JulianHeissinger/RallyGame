extends "res://tests/test_case.gd"


func _meter(stats: StatBlock) -> UpgradeMeter:
	var params := StageParams.new()
	params.upgrade_distance = 800.0
	params.upgrade_hazard_bonus = 0.05
	var meter := UpgradeMeter.new()
	meter.setup(params, stats)
	return meter


func test_progress_fills_and_overflow_carries() -> void:
	var meter := _meter(StatBlock.new({"hazard_bonus_scale": 1.0}))
	var fills := [0]
	meter.filled.connect(func() -> void: fills[0] += 1)
	meter.add_progress(400.0)
	assert_almost_eq(meter.value, 0.5, 0.0001, "half the distance, half the meter")
	assert_eq(fills[0], 0, "not full yet")
	meter.add_progress(480.0)
	assert_eq(fills[0], 1, "fills once")
	assert_almost_eq(meter.value, 0.1, 0.0001, "overflow carries over")
	meter.free()


func test_hazard_hunter_doubles_the_hazard_bonus() -> void:
	var stats := StatBlock.new({"hazard_bonus_scale": 1.0})
	var meter := _meter(stats)
	meter.add_hazard_bonus()
	assert_almost_eq(meter.value, 0.05, 0.0001, "plain bonus")
	var damage := CarDamage.new()
	var items := ItemManager.new()
	items.setup(null, stats, damage)
	items.add_item(load("res://data/items/hazard_hunter.tres"))
	meter.add_hazard_bonus()
	assert_almost_eq(meter.value, 0.15, 0.0001, "Hazard Hunter doubles it")
	for node in [meter, damage, items]:
		node.free()


func test_offers_are_distinct_seeded_and_skip_mounted_items() -> void:
	var pool := ItemPool.load_all()
	assert_true(pool.size() >= 30, "pool holds every item file")
	var damage := CarDamage.new()
	var items := ItemManager.new()
	items.setup(null, StatBlock.new({}), damage)
	var ids := func(offers: Array[ItemDef]) -> Array: return offers.map(func(def: ItemDef) -> String: return def.id)
	var first: Array = ids.call(ItemPool.offer(pool, items, SeedStreams.rng(42, "upgrades"), 3))
	assert_eq(first.size(), 3, "three offers")
	assert_eq(first, ids.call(ItemPool.offer(pool, items, SeedStreams.rng(42, "upgrades"), 3)), "same seed, same offers")
	for i in 50:
		var offers: Array = ids.call(ItemPool.offer(pool, items, SeedStreams.rng(i, "upgrades"), 3))
		assert_true(offers[0] != offers[1] and offers[1] != offers[2] and offers[0] != offers[2], "distinct offers")
	var nitro: ItemDef = load("res://data/items/nitro.tres")
	items.add_item(nitro)
	for i in 50:
		var offers: Array = ids.call(ItemPool.offer(pool, items, SeedStreams.rng(i, "upgrades"), 3))
		assert_false(offers.has("nitro"), "mounted item not offered again")
	damage.free()
	items.free()
