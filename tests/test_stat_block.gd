extends "res://tests/test_case.gd"


func test_stacking_order() -> void:
	var block := StatBlock.new({"grip": 10.0})
	block.additive["grip"] = 2.0
	block.multiplicative["grip"] = 3.0
	block.damage_multiplier["grip"] = 0.5
	block.mark_dirty()
	# (10 + 2) * 3 * 0.5 = 18
	assert_almost_eq(block.get_stat("grip"), 18.0, 0.0001, "additive, then multiplicative, then damage")


func test_missing_modifiers_default_to_identity() -> void:
	var block := StatBlock.new({"mass": 1200.0})
	assert_almost_eq(block.get_stat("mass"), 1200.0, 0.0001, "no modifiers leaves base unchanged")


func test_recomputes_only_after_mark_dirty() -> void:
	var block := StatBlock.new({"grip": 10.0})
	assert_almost_eq(block.get_stat("grip"), 10.0, 0.0001, "initial read")
	block.additive["grip"] = 5.0
	assert_almost_eq(block.get_stat("grip"), 10.0, 0.0001, "stale cache until marked dirty")
	block.mark_dirty()
	assert_almost_eq(block.get_stat("grip"), 15.0, 0.0001, "recomputed after mark_dirty")
