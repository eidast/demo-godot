extends Node2D

const TARGET_CELL_SIZE := 24.0
const UI_MARGIN := 16.0
const UI_PANEL_HEIGHT := 182.0
const MIN_GRID_WIDTH := 20
const MIN_GRID_HEIGHT := 28
const FUN_REPEAT_THRESHOLD := 50

const DEAD_COLOR := Color("12202d")
const LIVE_COLOR := Color("78f3ff")
const GRID_LINE_COLOR := Color("2d4154")
const HUD_PANEL_COLOR := Color("101814")
const HUD_BORDER_COLOR := Color("74dc62")
const HUD_BUTTON_COLOR := Color("223326")
const HUD_BUTTON_HOVER_COLOR := Color("2c4332")
const HUD_BUTTON_PRESSED_COLOR := Color("1b2a1f")
const HUD_TEXT_PRIMARY := Color("e7f9bf")
const HUD_TEXT_SECONDARY := Color("9be06b")

const UI_FONT := preload("res://assets/fonts/VT323-Regular.ttf")

@onready var simulation_timer: Timer = $SimulationTimer
@onready var gameplay_music: AudioStreamPlayer = $GameplayMusic

var current_grid: PackedInt32Array = PackedInt32Array()
var next_grid: PackedInt32Array = PackedInt32Array()
var is_running := false
var generation := 0
var live_cells := 0
var grid_width := MIN_GRID_WIDTH
var grid_height := MIN_GRID_HEIGHT
var cell_size := TARGET_CELL_SIZE
var board_origin := Vector2.ZERO
var board_size := Vector2.ZERO
var drag_paint_value := -1
var last_touched_cell := Vector2i(-1, -1)
var is_fun_mode := false
var fun_repeat_generations := 0
var previous_grid_state: PackedInt32Array = PackedInt32Array()
var two_steps_back_grid_state: PackedInt32Array = PackedInt32Array()

var generation_label: Label
var live_cells_label: Label
var play_pause_button: Button
var clear_button: Button
var random_button: Button
var back_button: Button
var speed_label: Label
var speed_slider: HSlider
var hud_margin: MarginContainer
var safe_insets := {
	"left": int(UI_MARGIN),
	"top": int(UI_MARGIN),
	"right": int(UI_MARGIN),
	"bottom": int(UI_MARGIN),
}


func _ready() -> void:
	_build_ui()
	_apply_translations()
	simulation_timer.timeout.connect(_on_simulation_timer_timeout)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_update_safe_area()
	_rebuild_board()


func _initialize_grids() -> void:
	var cell_count: int = grid_width * grid_height
	current_grid.resize(cell_count)
	next_grid.resize(cell_count)
	_clear_grid_data()


func _build_ui() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	add_child(layer)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", int(UI_MARGIN))
	margin.add_theme_constant_override("margin_top", int(UI_MARGIN))
	margin.add_theme_constant_override("margin_right", int(UI_MARGIN))
	margin.add_theme_constant_override("margin_bottom", int(UI_MARGIN))
	layer.add_child(margin)
	hud_margin = margin

	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_stylebox())
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	margin.add_child(panel)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	panel.add_child(root)

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	root.add_child(top_row)

	play_pause_button = _make_button(Vector2(118, 64), 26)
	play_pause_button.pressed.connect(_toggle_play_pause)
	top_row.add_child(play_pause_button)

	clear_button = _make_button(Vector2(118, 64), 26)
	clear_button.pressed.connect(_on_clear_pressed)
	top_row.add_child(clear_button)

	random_button = _make_button(Vector2(130, 64), 26)
	random_button.pressed.connect(_on_random_pressed)
	top_row.add_child(random_button)

	back_button = _make_button(Vector2(108, 64), 26)
	back_button.pressed.connect(_go_to_menu)
	top_row.add_child(back_button)

	var bottom_row: HBoxContainer = HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 12)
	root.add_child(bottom_row)

	speed_label = _make_label(20, HUD_TEXT_SECONDARY)
	bottom_row.add_child(speed_label)

	speed_slider = HSlider.new()
	speed_slider.min_value = 2.0
	speed_slider.max_value = 18.0
	speed_slider.step = 1.0
	speed_slider.value = 8.0
	speed_slider.custom_minimum_size = Vector2(170, 56)
	speed_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speed_slider.value_changed.connect(_on_speed_slider_value_changed)
	speed_slider.add_theme_color_override("font_color", HUD_TEXT_PRIMARY)
	speed_slider.add_theme_color_override("font_outline_color", Color.BLACK)
	bottom_row.add_child(speed_slider)

	generation_label = _make_label(20, HUD_TEXT_PRIMARY)
	bottom_row.add_child(generation_label)

	live_cells_label = _make_label(20, HUD_TEXT_PRIMARY)
	bottom_row.add_child(live_cells_label)


func _make_button(min_size: Vector2, font_size: int) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = min_size
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_override("font", UI_FONT)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", HUD_TEXT_PRIMARY)
	button.add_theme_color_override("font_hover_color", HUD_TEXT_PRIMARY)
	button.add_theme_color_override("font_pressed_color", HUD_TEXT_PRIMARY)
	button.add_theme_color_override("font_focus_color", HUD_TEXT_PRIMARY)
	button.add_theme_color_override("font_outline_color", Color.BLACK)
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_stylebox_override("normal", _make_button_stylebox(HUD_BUTTON_COLOR, HUD_BORDER_COLOR))
	button.add_theme_stylebox_override("hover", _make_button_stylebox(HUD_BUTTON_HOVER_COLOR, HUD_BORDER_COLOR))
	button.add_theme_stylebox_override("pressed", _make_button_stylebox(HUD_BUTTON_PRESSED_COLOR, HUD_BORDER_COLOR))
	button.add_theme_stylebox_override("focus", _make_button_stylebox(HUD_BUTTON_HOVER_COLOR, HUD_BORDER_COLOR))
	return button


func _make_label(font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_override("font", UI_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	return label


func _make_panel_stylebox() -> StyleBoxFlat:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = HUD_PANEL_COLOR
	stylebox.border_width_left = 3
	stylebox.border_width_top = 3
	stylebox.border_width_right = 3
	stylebox.border_width_bottom = 3
	stylebox.border_color = HUD_BORDER_COLOR
	stylebox.corner_radius_top_left = 10
	stylebox.corner_radius_top_right = 10
	stylebox.corner_radius_bottom_right = 10
	stylebox.corner_radius_bottom_left = 10
	stylebox.content_margin_left = 12
	stylebox.content_margin_top = 12
	stylebox.content_margin_right = 12
	stylebox.content_margin_bottom = 12
	return stylebox


func _make_button_stylebox(fill_color: Color, border_color: Color) -> StyleBoxFlat:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = fill_color
	stylebox.border_width_left = 3
	stylebox.border_width_top = 3
	stylebox.border_width_right = 3
	stylebox.border_width_bottom = 3
	stylebox.border_color = border_color
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.content_margin_left = 8
	stylebox.content_margin_top = 8
	stylebox.content_margin_right = 8
	stylebox.content_margin_bottom = 8
	return stylebox


func _update_board_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var board_x: float = floorf((viewport_size.x - board_size.x) * 0.5)
	var board_y: float = float(safe_insets["top"]) + UI_PANEL_HEIGHT + UI_MARGIN
	var min_x: float = float(safe_insets["left"])
	var max_x: float = maxf(min_x, viewport_size.x - float(safe_insets["right"]) - board_size.x)
	board_origin = Vector2(clampf(board_x, min_x, max_x), board_y)
	queue_redraw()


func _draw() -> void:
	var board_rect: Rect2 = Rect2(board_origin, board_size)
	draw_rect(board_rect, DEAD_COLOR, true)
	draw_rect(board_rect, GRID_LINE_COLOR, false, 3.0)

	var line_width: float = 1.0 if cell_size < 18.0 else 2.0
	for x in range(1, grid_width):
		var line_x: float = board_origin.x + x * cell_size
		draw_line(
			Vector2(line_x, board_origin.y),
			Vector2(line_x, board_origin.y + board_size.y),
			GRID_LINE_COLOR,
			line_width
		)
	for y in range(1, grid_height):
		var line_y: float = board_origin.y + y * cell_size
		draw_line(
			Vector2(board_origin.x, line_y),
			Vector2(board_origin.x + board_size.x, line_y),
			GRID_LINE_COLOR,
			line_width
		)

	for y in range(grid_height):
		for x in range(grid_width):
			if _get_cell(current_grid, x, y) != 1:
				continue
			var cell_position: Vector2 = board_origin + Vector2(x * cell_size, y * cell_size)
			var inset: float = maxf(1.0, floorf(cell_size * 0.08))
			var cell_rect: Rect2 = Rect2(
				cell_position + Vector2(inset, inset),
				Vector2(cell_size - inset * 2.0, cell_size - inset * 2.0)
			)
			draw_rect(cell_rect, LIVE_COLOR, true)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_paint_at_position(event.position)
		else:
			_end_paint_gesture()
		return

	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_paint_at_position(event.position)
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_begin_paint_at_position(event.position)
		else:
			_end_paint_gesture()
		return

	if event is InputEventScreenDrag:
		_paint_at_position(event.position)
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				_toggle_play_pause()
			KEY_N:
				step_simulation()
			KEY_C:
				_on_clear_pressed()
			KEY_R:
				_on_random_pressed()


func step_simulation() -> void:
	var next_live_cells: int = 0

	for y in range(grid_height):
		for x in range(grid_width):
			var alive_neighbors: int = _count_neighbors(x, y)
			var currently_alive: bool = _get_cell(current_grid, x, y) == 1
			var next_alive: bool = false

			if currently_alive:
				next_alive = alive_neighbors == 2 or alive_neighbors == 3
			else:
				next_alive = alive_neighbors == 3

			_set_cell(next_grid, x, y, int(next_alive))
			if next_alive:
				next_live_cells += 1

	var temp: PackedInt32Array = current_grid
	current_grid = next_grid
	next_grid = temp
	live_cells = next_live_cells
	generation += 1

	if live_cells == 0:
		if is_fun_mode:
			_restart_fun_mode_cycle()
			return
		_seed_demo_pattern()
		return

	if is_fun_mode:
		_track_fun_mode_progress()
		if fun_repeat_generations >= FUN_REPEAT_THRESHOLD:
			_restart_fun_mode_cycle()
			return

	_update_stats_labels()
	queue_redraw()


func clear_grid() -> void:
	_clear_grid_data()
	generation = 0
	live_cells = 0
	_reset_fun_mode_tracking()
	_update_stats_labels()
	queue_redraw()


func randomize_grid() -> void:
	var new_live_cells: int = 0
	for i in range(current_grid.size()):
		var value: int = 1 if randf() > 0.62 else 0
		current_grid[i] = value
		next_grid[i] = 0
		new_live_cells += value

	live_cells = new_live_cells
	generation = 0
	_prime_fun_mode_tracking()
	_update_stats_labels()
	queue_redraw()


func _clear_grid_data() -> void:
	for i in range(current_grid.size()):
		current_grid[i] = 0
		next_grid[i] = 0


func _seed_demo_pattern() -> void:
	clear_grid()

	# Three simple, recognizable patterns to visually verify the board.
	var center_x: int = grid_width / 2
	var center_y: int = grid_height / 2
	_place_glider(2, 2)
	_place_blinker(max(2, center_x - 4), max(2, center_y - 6))
	_place_block(max(2, center_x + 3), max(2, center_y + 2))
	_place_toad(max(2, center_x - 6), max(4, center_y + 4))

	live_cells = _count_live_cells(current_grid)
	_update_stats_labels()
	queue_redraw()


func _place_glider(x: int, y: int) -> void:
	_set_live(x + 1, y)
	_set_live(x + 2, y + 1)
	_set_live(x, y + 2)
	_set_live(x + 1, y + 2)
	_set_live(x + 2, y + 2)


func _place_blinker(x: int, y: int) -> void:
	_set_live(x, y)
	_set_live(x + 1, y)
	_set_live(x + 2, y)


func _place_block(x: int, y: int) -> void:
	_set_live(x, y)
	_set_live(x + 1, y)
	_set_live(x, y + 1)
	_set_live(x + 1, y + 1)


func _place_toad(x: int, y: int) -> void:
	_set_live(x + 1, y)
	_set_live(x + 2, y)
	_set_live(x + 3, y)
	_set_live(x, y + 1)
	_set_live(x + 1, y + 1)
	_set_live(x + 2, y + 1)


func _set_live(x: int, y: int) -> void:
	if _is_inside_grid(x, y):
		_set_cell(current_grid, x, y, 1)


func _count_live_cells(grid: PackedInt32Array) -> int:
	var count: int = 0
	for i in range(grid.size()):
		count += grid[i]
	return count


func _toggle_play_pause() -> void:
	is_running = not is_running
	if is_running:
		simulation_timer.start()
	else:
		simulation_timer.stop()
	_update_play_pause_label()


func _start_simulation() -> void:
	is_running = true
	simulation_timer.start()
	_update_play_pause_label()


func _update_play_pause_label() -> void:
	if play_pause_button != null:
		play_pause_button.text = "||" if is_running else ">"


func _update_stats_labels() -> void:
	if generation_label != null:
		generation_label.text = GameSettings.get_text("generation") % generation
	if live_cells_label != null:
		live_cells_label.text = GameSettings.get_text("live_cells") % live_cells
	_update_music_state()


func _apply_translations() -> void:
	if clear_button != null:
		clear_button.text = GameSettings.get_text("fun")
	if random_button != null:
		random_button.text = GameSettings.get_text("random")
	if back_button != null:
		back_button.text = GameSettings.get_text("back")
	if speed_label != null:
		speed_label.text = GameSettings.get_text("speed")
	_update_play_pause_label()
	_update_stats_labels()


func _on_speed_slider_value_changed(value: float) -> void:
	simulation_timer.wait_time = 1.0 / value


func _on_simulation_timer_timeout() -> void:
	step_simulation()


func _on_clear_pressed() -> void:
	activate_fun_mode()


func _on_random_pressed() -> void:
	randomize_grid()
	_start_simulation()


func activate_fun_mode() -> void:
	is_fun_mode = true
	if speed_slider != null:
		speed_slider.value = speed_slider.max_value
		_on_speed_slider_value_changed(speed_slider.value)
	_restart_fun_mode_cycle()


func _begin_paint_at_position(pointer_position: Vector2) -> void:
	var cell: Vector2i = _cell_from_position(pointer_position)
	if cell.x < 0:
		_end_paint_gesture()
		return

	var is_alive: bool = _get_cell(current_grid, cell.x, cell.y) == 1
	drag_paint_value = int(not is_alive)
	last_touched_cell = Vector2i(-1, -1)
	_paint_at_position(pointer_position)


func _paint_at_position(pointer_position: Vector2) -> void:
	if drag_paint_value == -1:
		return

	var cell: Vector2i = _cell_from_position(pointer_position)
	if cell.x < 0 or cell == last_touched_cell:
		return

	_set_cell(current_grid, cell.x, cell.y, drag_paint_value)
	live_cells = _count_live_cells(current_grid)
	last_touched_cell = cell
	_prime_fun_mode_tracking()
	_update_stats_labels()
	queue_redraw()


func _end_paint_gesture() -> void:
	drag_paint_value = -1
	last_touched_cell = Vector2i(-1, -1)


func _cell_from_position(pointer_position: Vector2) -> Vector2i:
	var local_position: Vector2 = pointer_position - board_origin
	if local_position.x < 0.0 or local_position.y < 0.0:
		return Vector2i(-1, -1)

	var x: int = int(local_position.x / cell_size)
	var y: int = int(local_position.y / cell_size)

	if not _is_inside_grid(x, y):
		return Vector2i(-1, -1)

	return Vector2i(x, y)


func _count_neighbors(x: int, y: int) -> int:
	var neighbors: int = 0
	for offset_y in range(-1, 2):
		for offset_x in range(-1, 2):
			if offset_x == 0 and offset_y == 0:
				continue
			var nx: int = x + offset_x
			var ny: int = y + offset_y
			if _is_inside_grid(nx, ny):
				neighbors += _get_cell(current_grid, nx, ny)
	return neighbors


func _is_inside_grid(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < grid_width and y < grid_height


func _index(x: int, y: int) -> int:
	return y * grid_width + x


func _get_cell(grid: PackedInt32Array, x: int, y: int) -> int:
	return grid[_index(x, y)]


func _set_cell(grid: PackedInt32Array, x: int, y: int, value: int) -> void:
	grid[_index(x, y)] = value


func _on_viewport_size_changed() -> void:
	_update_safe_area()
	_rebuild_board()


func _go_to_menu() -> void:
	get_tree().change_scene_to_file("res://welcome.tscn")


func _rebuild_board() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var available_width: float = viewport_size.x - float(safe_insets["left"]) - float(safe_insets["right"])
	var available_height: float = viewport_size.y - float(safe_insets["top"]) - float(safe_insets["bottom"]) - UI_PANEL_HEIGHT - UI_MARGIN

	grid_width = max(MIN_GRID_WIDTH, int(floor(available_width / TARGET_CELL_SIZE)))
	grid_height = max(MIN_GRID_HEIGHT, int(floor(available_height / TARGET_CELL_SIZE)))
	cell_size = TARGET_CELL_SIZE
	board_size = Vector2(grid_width * cell_size, grid_height * cell_size)

	_initialize_grids()
	_update_board_layout()
	_seed_initial_state()
	_start_simulation()


func _seed_initial_state() -> void:
	randomize_grid()
	if live_cells == 0:
		randomize_grid()
	if live_cells == 0:
		_seed_demo_pattern()


func _restart_fun_mode_cycle() -> void:
	randomize_grid()
	_start_simulation()


func _track_fun_mode_progress() -> void:
	var matches_previous := previous_grid_state.size() == current_grid.size() and current_grid == previous_grid_state
	var matches_two_steps_back := two_steps_back_grid_state.size() == current_grid.size() and current_grid == two_steps_back_grid_state
	if matches_previous or matches_two_steps_back:
		fun_repeat_generations += 1
	else:
		fun_repeat_generations = 0
	two_steps_back_grid_state = previous_grid_state.duplicate()
	previous_grid_state = current_grid.duplicate()


func _reset_fun_mode_tracking() -> void:
	fun_repeat_generations = 0
	previous_grid_state = PackedInt32Array()
	two_steps_back_grid_state = PackedInt32Array()


func _prime_fun_mode_tracking() -> void:
	_reset_fun_mode_tracking()
	previous_grid_state = current_grid.duplicate()


func _update_safe_area() -> void:
	var viewport_size := Vector2i(get_viewport_rect().size)
	var raw_insets: Dictionary = SafeArea.get_insets(viewport_size)
	safe_insets = {
		"left": max(6, int(ceil(float(raw_insets["left"]) * 0.5)) + 2),
		"top": max(6, int(ceil(float(raw_insets["top"]) * 0.5)) + 2),
		"right": max(6, int(ceil(float(raw_insets["right"]) * 0.5)) + 2),
		"bottom": max(6, int(ceil(float(raw_insets["bottom"]) * 0.5)) + 2),
	}
	if hud_margin != null:
		hud_margin.add_theme_constant_override("margin_left", safe_insets["left"])
		hud_margin.add_theme_constant_override("margin_top", safe_insets["top"])
		hud_margin.add_theme_constant_override("margin_right", safe_insets["right"])
		hud_margin.add_theme_constant_override("margin_bottom", safe_insets["bottom"])


func _update_music_state() -> void:
	if gameplay_music == null:
		return
	if gameplay_music.has_method("update_state"):
		gameplay_music.call("update_state", live_cells, grid_width * grid_height, is_running)
