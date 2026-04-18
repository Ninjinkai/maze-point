extends RefCounted
class_name MazeGenerator

const DIRS := [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
const DIR_BITS := [1, 2, 4, 8]
const OPPOSITE_BITS := [4, 8, 1, 2]


static func generate(width: int, height: int, seed: int) -> Dictionary:
	var cells: Array[PackedInt32Array] = []
	var visited: Array[PackedByteArray] = []

	for y in range(height):
		var cell_row := PackedInt32Array()
		cell_row.resize(width)
		cells.append(cell_row)

		var visited_row := PackedByteArray()
		visited_row.resize(width)
		visited.append(visited_row)

	var stack: Array[Vector2i] = [Vector2i.ZERO]
	var visited_count := 1
	visited[0][0] = 1

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	while visited_count < width * height:
		var current := stack[stack.size() - 1]
		var options: Array[int] = []

		for dir_index in range(DIRS.size()):
			var candidate: Vector2i = current + DIRS[dir_index]
			if not _is_inside(candidate, width, height):
				continue
			if visited[candidate.y][candidate.x] != 0:
				continue
			options.append(dir_index)

		if options.is_empty():
			stack.pop_back()
			continue

		var dir_index := options[rng.randi_range(0, options.size() - 1)]
		var next_cell: Vector2i = current + DIRS[dir_index]

		cells[current.y][current.x] |= DIR_BITS[dir_index]
		cells[next_cell.y][next_cell.x] |= OPPOSITE_BITS[dir_index]
		visited[next_cell.y][next_cell.x] = 1
		visited_count += 1
		stack.append(next_cell)

	var start_sweep: Dictionary = _find_farthest(cells, width, height, Vector2i.ZERO)
	var start: Vector2i = start_sweep["cell"]
	var goal_sweep: Dictionary = _find_farthest(cells, width, height, start)
	var goal: Vector2i = goal_sweep["cell"]
	var goal_bfs: Dictionary = _bfs(cells, width, height, goal)
	var solution_path: Array[Vector2i] = _reconstruct_path(goal_sweep["previous"], start, goal)

	return {
		"cells": cells,
		"start": start,
		"goal": goal,
		"solution_path": solution_path,
		"solution_length": max(solution_path.size() - 1, 0),
		"goal_previous": goal_bfs["previous"],
	}


static func connected_neighbors(cells: Array[PackedInt32Array], width: int, height: int, cell: Vector2i) -> Array[Vector2i]:
	var results: Array[Vector2i] = []
	var mask := cells[cell.y][cell.x]

	for dir_index in range(DIRS.size()):
		if (mask & DIR_BITS[dir_index]) == 0:
			continue

		var candidate: Vector2i = cell + DIRS[dir_index]
		if _is_inside(candidate, width, height):
			results.append(candidate)

	return results


static func has_connection(cells: Array[PackedInt32Array], cell: Vector2i, direction: Vector2i) -> bool:
	var dir_index := DIRS.find(direction)
	if dir_index == -1:
		return false
	return (cells[cell.y][cell.x] & DIR_BITS[dir_index]) != 0


static func _find_farthest(cells: Array[PackedInt32Array], width: int, height: int, start: Vector2i) -> Dictionary:
	var bfs: Dictionary = _bfs(cells, width, height, start)
	var distances: Dictionary = bfs["distances"]
	var farthest := start

	for candidate_variant in distances.keys():
		var candidate: Vector2i = candidate_variant
		if distances[candidate] > distances[farthest]:
			farthest = candidate

	return {
		"cell": farthest,
		"previous": bfs["previous"],
		"distances": distances,
	}


static func _bfs(cells: Array[PackedInt32Array], width: int, height: int, start: Vector2i) -> Dictionary:
	var queue: Array[Vector2i] = [start]
	var distances: Dictionary = {start: 0}
	var previous: Dictionary = {}
	var index := 0

	while index < queue.size():
		var current := queue[index]
		index += 1
		var current_distance: int = distances[current]

		for neighbor in connected_neighbors(cells, width, height, current):
			if distances.has(neighbor):
				continue
			distances[neighbor] = current_distance + 1
			previous[neighbor] = current
			queue.append(neighbor)

	return {
		"distances": distances,
		"previous": previous,
	}


static func _reconstruct_path(previous: Dictionary, start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [goal]
	var current := goal

	while current != start and previous.has(current):
		current = previous[current]
		path.append(current)

	path.reverse()
	return path


static func _is_inside(cell: Vector2i, width: int, height: int) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height
