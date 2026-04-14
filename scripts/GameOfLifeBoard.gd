class_name GameOfLifeBoard
extends RefCounted

var width: int
var height: int
var current_grid: PackedInt32Array = PackedInt32Array()
var next_grid: PackedInt32Array = PackedInt32Array()
var generation: int = 0
var live_cells: int = 0


func _init(board_width: int, board_height: int) -> void:
	resize_board(board_width, board_height)


func resize_board(board_width: int, board_height: int) -> void:
	width = max(1, board_width)
	height = max(1, board_height)
	var cell_count: int = width * height
	current_grid.resize(cell_count)
	next_grid.resize(cell_count)
	clear()


func clear() -> void:
	for i in range(current_grid.size()):
		current_grid[i] = 0
		next_grid[i] = 0
	generation = 0
	live_cells = 0


func randomize_board(alive_probability: float = 0.38, seed: int = -1) -> void:
	var rng := RandomNumberGenerator.new()
	if seed >= 0:
		rng.seed = seed
	else:
		rng.randomize()

	var new_live_cells: int = 0
	for i in range(current_grid.size()):
		var value: int = 1 if rng.randf() < alive_probability else 0
		current_grid[i] = value
		next_grid[i] = 0
		new_live_cells += value

	generation = 0
	live_cells = new_live_cells


func seed_demo_pattern() -> void:
	clear()
	var center_x: int = width / 2
	var center_y: int = height / 2
	place_glider(2, 2)
	place_blinker(max(2, center_x - 4), max(2, center_y - 6))
	place_block(max(2, center_x + 3), max(2, center_y + 2))
	place_toad(max(2, center_x - 6), max(4, center_y + 4))
	live_cells = count_live_cells(current_grid)


func step() -> void:
	var next_live_cells: int = 0
	for y in range(height):
		for x in range(width):
			var alive_neighbors: int = count_neighbors(x, y)
			var currently_alive: bool = get_cell(current_grid, x, y) == 1
			var next_alive: bool = false
			if currently_alive:
				next_alive = alive_neighbors == 2 or alive_neighbors == 3
			else:
				next_alive = alive_neighbors == 3

			set_cell(next_grid, x, y, int(next_alive))
			if next_alive:
				next_live_cells += 1

	var temp: PackedInt32Array = current_grid
	current_grid = next_grid
	next_grid = temp
	live_cells = next_live_cells
	generation += 1


func place_glider(x: int, y: int) -> void:
	set_live(x + 1, y)
	set_live(x + 2, y + 1)
	set_live(x, y + 2)
	set_live(x + 1, y + 2)
	set_live(x + 2, y + 2)


func place_blinker(x: int, y: int) -> void:
	set_live(x, y)
	set_live(x + 1, y)
	set_live(x + 2, y)


func place_block(x: int, y: int) -> void:
	set_live(x, y)
	set_live(x + 1, y)
	set_live(x, y + 1)
	set_live(x + 1, y + 1)


func place_toad(x: int, y: int) -> void:
	set_live(x + 1, y)
	set_live(x + 2, y)
	set_live(x + 3, y)
	set_live(x, y + 1)
	set_live(x + 1, y + 1)
	set_live(x + 2, y + 1)


func set_live(x: int, y: int) -> void:
	if is_inside(x, y):
		set_cell(current_grid, x, y, 1)
		live_cells = count_live_cells(current_grid)


func count_live_cells(grid: PackedInt32Array = current_grid) -> int:
	var count: int = 0
	for value in grid:
		count += value
	return count


func count_neighbors(x: int, y: int) -> int:
	var neighbors: int = 0
	for offset_y in range(-1, 2):
		for offset_x in range(-1, 2):
			if offset_x == 0 and offset_y == 0:
				continue
			var nx: int = x + offset_x
			var ny: int = y + offset_y
			if is_inside(nx, ny):
				neighbors += get_cell(current_grid, nx, ny)
	return neighbors


func is_inside(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < width and y < height


func index(x: int, y: int) -> int:
	return y * width + x


func get_cell(grid: PackedInt32Array, x: int, y: int) -> int:
	return grid[index(x, y)]


func set_cell(grid: PackedInt32Array, x: int, y: int, value: int) -> void:
	grid[index(x, y)] = value
