extends "res://tests/test_case.gd"


func test_grass_grips_less_than_gravel() -> void:
	var gravel := Node.new()
	gravel.set_meta("surface", "gravel")
	var grass := Node.new()
	grass.set_meta("surface", "grass")
	assert_true(Surface.grip_of(grass) < Surface.grip_of(gravel), "grass below gravel")
	gravel.free()
	grass.free()


func test_missing_or_unknown_surface_uses_default() -> void:
	var plain := Node.new()
	var unknown := Node.new()
	unknown.set_meta("surface", "lava")
	assert_eq(Surface.name_of(null), Surface.DEFAULT, "null collider")
	assert_eq(Surface.name_of(plain), Surface.DEFAULT, "no metadata")
	assert_eq(Surface.name_of(unknown), Surface.DEFAULT, "unknown surface")
	plain.free()
	unknown.free()
