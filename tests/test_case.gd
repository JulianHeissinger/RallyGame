extends RefCounted
## Base for test files. Failed asserts are recorded, not fatal, so one run reports every failure.

var failures: PackedStringArray = []


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		_fail("expected true", message)


func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		_fail("expected false", message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		_fail("expected %s, got %s" % [expected, actual], message)


func assert_almost_eq(actual: float, expected: float, epsilon: float, message: String = "") -> void:
	if absf(actual - expected) > epsilon:
		_fail("expected %s ± %s, got %s" % [expected, epsilon, actual], message)


func _fail(reason: String, message: String) -> void:
	failures.append(reason if message.is_empty() else "%s: %s" % [message, reason])
