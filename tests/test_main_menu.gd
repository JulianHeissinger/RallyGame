extends "res://tests/test_case.gd"


func test_parse_seed() -> void:
	var menu: GDScript = load("res://scripts/ui/main_menu.gd")
	assert_eq(menu.parse_seed(""), 0, "empty: random")
	assert_eq(menu.parse_seed("42"), 42, "entered seed")
	assert_eq(menu.parse_seed("0"), 0, "zero: random")
