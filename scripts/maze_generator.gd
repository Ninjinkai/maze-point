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
		_add_connection(cells, current, dir_index)
		visited[next_cell.y][next_cell.x] = 1
		visited_count += 1
		stack.append(next_cell)

	_add_extra_connections(cells, width, height, rng)

	var start_sweep: Dictionary = _find_farthest(cells, width, height, Vector2i.ZERO)
	var start: Vector2i = start_sweep["cell"]
	var goal_sweep: Dictionary = _find_farthest(cells, width, height, start)
	var goal: Vector2i = goal_sweep["cell"]
	var start_bfs: Dictionary = _bfs(cells, width, height, start)
	var solution_path: Array[Vector2i] = _reconstruct_path(start_bfs["previous"], start, goal)

	return {
		"cells": cells,
		"start": start,
		"goal": goal,
		"solution_path": solution_path,
		"solution_length": max(solution_path.size() - 1, 0),
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


static func _add_extra_connections(cells: Array[PackedInt32Array], width: int, height: int, rng: RandomNumberGenerator) -> void:
	var candidates := _build_connection_candidates(cells, width, height)
	var extra_connections: int = mini(_count_extra_connections(width, height), candidates.size())

	for _unused in range(extra_connections):
		if candidates.is_empty():
			return

		var index: int = rng.randi_range(0, candidates.size() - 1)
		var candidate: Dictionary = candidates[index]
		candidates.remove_at(index)

		var cell: Vector2i = candidate["cell"]
		var dir_index: int = candidate["dir_index"]
		_add_connection(cells, cell, dir_index)


static func _build_connection_candidates(cells: Array[PackedInt32Array], width: int, height: int) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []

	for y in range(height):
		for x in range(width):
			var cell := Vector2i(x, y)

			for dir_index in [0, 1]:
				var neighbor: Vector2i = cell + DIRS[dir_index]
				if not _is_inside(neighbor, width, height):
					continue
				if has_connection(cells, cell, DIRS[dir_index]):
					continue

				candidates.append({
					"cell": cell,
					"dir_index": dir_index,
				})

	return candidates


static func _count_extra_connections(width: int, height: int) -> int:
	var area := width * height
	var ratio := clampf(0.03 + float(width + height) / 180.0, 0.05, 0.14)
	return max(1, int(round(float(area) * ratio)))


static func _add_connection(cells: Array[PackedInt32Array], cell: Vector2i, dir_index: int) -> void:
	var next_cell: Vector2i = cell + DIRS[dir_index]
	cells[cell.y][cell.x] |= DIR_BITS[dir_index]
	cells[next_cell.y][next_cell.x] |= OPPOSITE_BITS[dir_index]


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
