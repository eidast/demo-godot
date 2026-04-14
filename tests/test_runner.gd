extends SceneTree

const GameOfLifeBoard := preload("res://scripts/GameOfLifeBoard.gd")
const GameSettingsScript := preload("res://scripts/GameSettings.gd")
const SafeAreaScript := preload("res://scripts/SafeArea.gd")

var failures: Array[String] = []
var assertions: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_game_of_life_board_rules()
	await _test_game_scene_smoke()
	await _test_safe_area_helpers()
	await _test_language_defaults()

	if failures.is_empty():
		print("All %d assertions passed." % assertions)
		quit(0)
		return

	push_error("Test failures: %d" % failures.size())
	for failure in failures:
		push_error(failure)
	quit(1)


func _test_game_of_life_board_rules() -> void:
	var board := GameOfLifeBoard.new(20, 20)

	board.place_blinker(2, 3)
	_assert_eq(board.live_cells, 3, "Blinker should start with 3 live cells.")
	board.step()
	_assert_eq(board.generation, 1, "Step should increment generation.")
	_assert_true(board.get_cell(board.current_grid, 3, 2) == 1, "Blinker should rotate vertically.")
	_assert_true(board.get_cell(board.current_grid, 3, 3) == 1, "Blinker center cell should remain alive.")
	_assert_true(board.get_cell(board.current_grid, 3, 4) == 1, "Blinker should rotate vertically.")
	_assert_eq(board.live_cells, 3, "Blinker should keep 3 live cells after one step.")
	board.step()
	_assert_true(board.get_cell(board.current_grid, 2, 3) == 1, "Blinker should rotate back horizontally.")
	_assert_true(board.get_cell(board.current_grid, 3, 3) == 1, "Blinker center cell should remain alive after two steps.")
	_assert_true(board.get_cell(board.current_grid, 4, 3) == 1, "Blinker should rotate back horizontally.")

	board.clear()
	board.place_block(3, 3)
	var stable_before: PackedInt32Array = board.current_grid.duplicate()
	board.step()
	_assert_true(board.current_grid == stable_before, "Block pattern should remain stable.")

	board.seed_demo_pattern()
	_assert_eq(board.live_cells, 18, "Demo pattern should seed 18 live cells.")

	var random_board := GameOfLifeBoard.new(10, 12)
	random_board.randomize_board(0.5, 42)
	_assert_eq(random_board.current_grid.size(), 120, "Randomized board should match board dimensions.")
	_assert_true(random_board.live_cells > 0, "Randomized board should usually contain live cells.")


func _test_game_scene_smoke() -> void:
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame

	_assert_true(scene.grid_width >= scene.MIN_GRID_WIDTH, "Scene grid width should respect the minimum.")
	_assert_true(scene.grid_height >= scene.MIN_GRID_HEIGHT, "Scene grid height should respect the minimum.")
	_assert_true(scene.live_cells > 0, "Scene should seed visible live cells on startup.")
	_assert_true(scene.is_running, "Scene should start simulation automatically.")

	scene.clear_grid()
	_assert_eq(scene.live_cells, 0, "Clear should reset the board.")
	scene.step_simulation()
	_assert_true(scene.live_cells > 0, "An empty board step should reseed the demo pattern.")
	_assert_true(scene.generation == 0 or scene.generation == 1, "Reseed path should keep generation bounded.")

	scene.activate_fun_mode()
	_assert_true(scene.is_fun_mode, "FUN mode should stay enabled after activation.")
	_assert_eq(scene.speed_slider.value, scene.speed_slider.max_value, "FUN mode should jump to max speed.")

	scene.clear_grid()
	scene.is_fun_mode = true
	scene._set_cell(scene.current_grid, 3, 3, 1)
	scene._set_cell(scene.current_grid, 4, 3, 1)
	scene._set_cell(scene.current_grid, 3, 4, 1)
	scene._set_cell(scene.current_grid, 4, 4, 1)
	scene.live_cells = scene._count_live_cells(scene.current_grid)
	scene._prime_fun_mode_tracking()
	scene.fun_repeat_generations = scene.FUN_REPEAT_THRESHOLD - 1
	scene.step_simulation()
	_assert_eq(scene.generation, 0, "FUN mode should restart from a fresh random board after a repeated pattern threshold.")
	_assert_true(scene.live_cells > 0, "FUN mode restart should leave a visible randomized board.")
	_assert_eq(scene.fun_repeat_generations, 0, "FUN mode restart should reset the repeat counter.")
	_assert_true(scene.is_running, "FUN mode restart should keep the simulation running.")

	root.remove_child(scene)
	scene.free()
	await process_frame


func _test_safe_area_helpers() -> void:
	var helper := SafeAreaScript.new()
	var viewport_size := Vector2i(1440, 3120)
	var safe_rect := Rect2i(Vector2i(32, 96), Vector2i(1376, 2960))
	var insets: Dictionary = helper.get_insets_from_safe_rect(viewport_size, safe_rect)

	_assert_eq(insets["left"], 32, "Safe area helper should preserve the left inset.")
	_assert_eq(insets["top"], 96, "Safe area helper should preserve the top inset.")
	_assert_eq(insets["right"], 32, "Safe area helper should calculate the right inset.")
	_assert_eq(insets["bottom"], 64, "Safe area helper should calculate the bottom inset.")


func _test_language_defaults() -> void:
	var settings := GameSettingsScript.new()
	_assert_eq(settings.get_language(), settings.LANGUAGE_ENGLISH, "Default language should be English.")
	_assert_eq(settings.get_text("start"), "Start", "English text should be the default lookup.")
	settings.set_language(settings.LANGUAGE_SPANISH)
	_assert_eq(settings.get_text("settings"), "Configuracion", "Spanish translation should still be available.")


func _assert_true(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)


func _assert_eq(actual, expected, message: String) -> void:
	assertions += 1
	if actual != expected:
		failures.append("%s Expected %s, got %s." % [message, str(expected), str(actual)])
