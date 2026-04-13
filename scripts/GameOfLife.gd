extends Node2D

const GRID_WIDTH := 80
const GRID_HEIGHT := 50
const CELL_SIZE := 16

const BG_COLOR := Color("11131a")
const DEAD_COLOR := Color("222633")
const LIVE_COLOR := Color("3fc1ff")
const GRID_LINE_COLOR := Color("2d3344")

@onready var simulation_timer: Timer = $SimulationTimer

var current_grid: PackedInt32Array = PackedInt32Array()
var next_grid: PackedInt32Array = PackedInt32Array()
var is_running := false
var generation := 0

var generation_label: Label
var play_pause_button: Button


func _ready() -> void:
	_initialize_grids()
	_build_ui()
	_update_generation_label()
	_update_play_pause_label()
	simulation_timer.timeout.connect(_on_simulation_timer_timeout)


func _initialize_grids() -> void:
	var cell_count := GRID_WIDTH * GRID_HEIGHT
	current_grid.resize(cell_count)
	next_grid.resize(cell_count)
	clear_grid()


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var panel := PanelContainer.new()
	panel.position = Vector2(10, 10)
	layer.add_child(panel)

	var row := HBoxContainer.new()
	panel.add_child(row)

	var step_button := Button.new()
	step_button.text = "Paso"
	step_button.pressed.connect(step_simulation)
	row.add_child(step_button)

	play_pause_button = Button.new()
	play_pause_button.pressed.connect(_toggle_play_pause)
	row.add_child(play_pause_button)

	var clear_button := Button.new()
	clear_button.text = "Limpiar"
	clear_button.pressed.connect(clear_grid)
	row.add_child(clear_button)

	var random_button := Button.new()
	random_button.text = "Aleatorio"
	random_button.pressed.connect(randomize_grid)
	row.add_child(random_button)

	var speed_label := Label.new()
	speed_label.text = "Velocidad"
	row.add_child(speed_label)

	var speed_slider := HSlider.new()
	speed_slider.min_value = 1.0
	speed_slider.max_value = 20.0
	speed_slider.step = 1.0
	speed_slider.value = 8.0
	speed_slider.custom_minimum_size = Vector2(120, 0)
	speed_slider.value_changed.connect(_on_speed_slider_value_changed)
	row.add_child(speed_slider)

	generation_label = Label.new()
	row.add_child(generation_label)


func _draw() -> void:
	var board_rect := Rect2(Vector2.ZERO, Vector2(GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE))
	draw_rect(board_rect, BG_COLOR, true)

	for y in GRID_HEIGHT:
		for x in GRID_WIDTH:
			var cell_rect := Rect2(Vector2(x * CELL_SIZE, y * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))
			var color := LIVE_COLOR if _get_cell(current_grid, x, y) == 1 else DEAD_COLOR
			draw_rect(cell_rect, color, true)
			draw_rect(cell_rect, GRID_LINE_COLOR, false, 1.0)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_toggle_cell_from_mouse(event.position)
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				_toggle_play_pause()
			KEY_N:
				step_simulation()
			KEY_C:
				clear_grid()
			KEY_R:
				randomize_grid()


func step_simulation() -> void:
	for y in GRID_HEIGHT:
		for x in GRID_WIDTH:
			var alive_neighbors := _count_neighbors(x, y)
			var currently_alive := _get_cell(current_grid, x, y) == 1
			var next_alive := currently_alive

			if currently_alive:
				next_alive = alive_neighbors == 2 or alive_neighbors == 3
			else:
				next_alive = alive_neighbors == 3

			_set_cell(next_grid, x, y, int(next_alive))

	var temp := current_grid
	current_grid = next_grid
	next_grid = temp
	generation += 1
	_update_generation_label()
	queue_redraw()


func clear_grid() -> void:
	for i in current_grid.size():
		current_grid[i] = 0
		next_grid[i] = 0
	generation = 0
	_update_generation_label()
	queue_redraw()


func randomize_grid() -> void:
	for i in current_grid.size():
		current_grid[i] = 1 if randf() > 0.78 else 0
		next_grid[i] = 0
	generation = 0
	_update_generation_label()
	queue_redraw()


func _toggle_play_pause() -> void:
	is_running = not is_running
	if is_running:
		simulation_timer.start()
	else:
		simulation_timer.stop()
	_update_play_pause_label()


func _update_play_pause_label() -> void:
	if play_pause_button == null:
		return
	play_pause_button.text = "Pausar" if is_running else "Play"


func _update_generation_label() -> void:
	if generation_label == null:
		return
	generation_label.text = "Gen: %d" % generation


func _on_speed_slider_value_changed(value: float) -> void:
	simulation_timer.wait_time = 1.0 / value


func _on_simulation_timer_timeout() -> void:
	step_simulation()


func _toggle_cell_from_mouse(mouse_position: Vector2) -> void:
	var x := int(mouse_position.x / CELL_SIZE)
	var y := int(mouse_position.y / CELL_SIZE)

	if not _is_inside_grid(x, y):
		return

	var is_alive := _get_cell(current_grid, x, y) == 1
	_set_cell(current_grid, x, y, int(not is_alive))
	queue_redraw()


func _count_neighbors(x: int, y: int) -> int:
	var neighbors := 0
	for offset_y in range(-1, 2):
		for offset_x in range(-1, 2):
			if offset_x == 0 and offset_y == 0:
				continue
			var nx := x + offset_x
			var ny := y + offset_y
			if _is_inside_grid(nx, ny):
				neighbors += _get_cell(current_grid, nx, ny)
	return neighbors


func _is_inside_grid(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < GRID_WIDTH and y < GRID_HEIGHT


func _index(x: int, y: int) -> int:
	return y * GRID_WIDTH + x


func _get_cell(grid: PackedInt32Array, x: int, y: int) -> int:
	return grid[_index(x, y)]


func _set_cell(grid: PackedInt32Array, x: int, y: int, value: int) -> void:
	grid[_index(x, y)] = value
