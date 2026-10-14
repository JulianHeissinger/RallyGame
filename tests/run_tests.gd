extends SceneTree
## Headless test runner: godot --headless --path . -s tests/run_tests.gd
## Runs every test_* method in res://tests/test_*.gd and exits non-zero on any failure.
## A test also fails if it logs an engine or script error, e.g. a null access.

const TESTS_DIR := "res://tests"

var _error_logger := ErrorLogger.new()


func _initialize() -> void:
	OS.add_logger(_error_logger)
	# Deferred so root is inside the tree and tests can add nodes.
	_run.call_deferred()


func _run() -> void:
	var passed := 0
	var failed := 0

	for file_name in _test_files():
		var path := TESTS_DIR.path_join(file_name)
		var script := load(path) as GDScript
		if script == null or not script.can_instantiate():
			print("FAIL %s: could not load" % path)
			failed += 1
			continue

		for method in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			var test_case: RefCounted = script.new()
			var errors_before := _error_logger.error_count()
			test_case.call(method_name)
			var failures: PackedStringArray = test_case.get("failures")
			var errors := _error_logger.error_count() - errors_before
			if errors > 0:
				failures.append("%d engine/script error(s) logged, see output above" % errors)
			if failures.is_empty():
				print("PASS %s::%s" % [file_name, method_name])
				passed += 1
			else:
				print("FAIL %s::%s" % [file_name, method_name])
				for failure in failures:
					print("    %s" % failure)
				failed += 1

	print("\n%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _test_files() -> PackedStringArray:
	var files: PackedStringArray = []
	for file_name in DirAccess.get_files_at(TESTS_DIR):
		if file_name.begins_with("test_") and file_name.ends_with(".gd") and file_name != "test_case.gd":
			files.append(file_name)
	files.sort()
	return files


## Counts logged errors (not warnings). Loggers can be called from any thread.
class ErrorLogger extends Logger:
	var _count := 0
	var _mutex := Mutex.new()

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		_mutex.lock()
		_count += 1
		_mutex.unlock()

	func error_count() -> int:
		_mutex.lock()
		var count := _count
		_mutex.unlock()
		return count
