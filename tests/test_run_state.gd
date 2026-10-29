extends "res://tests/test_case.gd"


func test_reset_clears_items_and_money() -> void:
	var run: Node = load("res://scripts/core/run_state.gd").new()
	run.stage_seed = 42
	run.difficulty = 3
	run.prize_money = 500
	run.add_item(load("res://data/items/nitro.tres"))
	run.add_item(load("res://data/items/rally_tyres.tres"))
	assert_eq(run.items.map(func(def: ItemDef) -> String: return def.id), ["nitro", "rally_tyres"], "picks in order")
	run.reset(7, 2)
	assert_eq(run.items.size(), 0, "no items after reset")
	assert_eq(run.prize_money, 0, "no money after reset")
	assert_eq(run.stage_seed, 7, "new seed")
	assert_eq(run.difficulty, 2, "new difficulty")
	run.reset()
	assert_eq(run.stage_seed, 0, "default reset: random seed")
	assert_eq(run.difficulty, 1, "default reset: difficulty 1")
	run.free()
