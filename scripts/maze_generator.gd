extends RefCounted
class_name MazeGenerator

const DIRS := [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
const DIR_BITS := [1, 2, 4, 8]
const OPPOSITE_BITS := [4, 8, 1, 2]
const BONUS_VALUE := 5


static func generate(width: int, height: int, seed: int, difficulty_scale: float = 1.0) -> Dictionary:
	var cells: Array[PackedInt32Array] = []
	var visited: Array[PackedByteArray] = []

	for y in range(height):
		var cell_row: PackedInt32Array = PackedInt32Array()
		cell_row.resize(width)
		cells.append(cell_row)

		var visited_row: PackedByteArray = PackedByteArray()
		visited_row.resize(width)
		visited.append(visited_row)

	var stack: Array[Vector2i] = [Vector2i.ZERO]
	var visited_count: int = 1
	visited[0][0] = 1

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed

	while visited_count < width * height:
		var current: Vector2i = stack[stack.size() - 1]
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

		var dir_index: int = options[rng.randi_range(0, options.size() - 1)]
		var next_cell: Vector2i = current + DIRS[dir_index]
		_add_connection(cells, current, dir_index)
		visited[next_cell.y][next_cell.x] = 1
		visited_count += 1
		stack.append(next_cell)

	_add_extra_connections(cells, width, height, rng, difficulty_scale)

	var start_sweep: Dictionary = _find_farthest(cells, width, height, Vector2i.ZERO)
	var start: Vector2i = start_sweep["cell"]
	var goal_sweep: Dictionary = _find_farthest(cells, width, height, start)
	var goal: Vector2i = goal_sweep["cell"]
	var start_bfs: Dictionary = _bfs(cells, width, height, start)
	var goal_bfs: Dictionary = _bfs(cells, width, height, goal)
	var solution_path: Array[Vector2i] = _reconstruct_path(start_bfs["previous"], start, goal)
	var bonuses: Array[Dictionary] = _build_bonuses(
		cells,
		width,
		height,
		start,
		goal,
		solution_path,
		start_bfs["distances"],
		goal_bfs["distances"],
		difficulty_scale,
		rng
	)

	return {
		"cells": cells,
		"start": start,
		"goal": goal,
		"solution_path": solution_path,
		"solution_length": max(solution_path.size() - 1, 0),
		"bonuses": bonuses,
		"perfect_score": 0,
	}


static func connected_neighbors(cells: Array[PackedInt32Array], width: int, height: int, cell: Vector2i) -> Array[Vector2i]:
	var results: Array[Vector2i] = []
	var mask: int = cells[cell.y][cell.x]

	for dir_index in range(DIRS.size()):
		if (mask & DIR_BITS[dir_index]) == 0:
			continue

		var candidate: Vector2i = cell + DIRS[dir_index]
		if _is_inside(candidate, width, height):
			results.append(candidate)

	return results


static func has_connection(cells: Array[PackedInt32Array], cell: Vector2i, direction: Vector2i) -> bool:
	var dir_index: int = DIRS.find(direction)
	if dir_index == -1:
		return false
	return (cells[cell.y][cell.x] & DIR_BITS[dir_index]) != 0


static func _add_extra_connections(cells: Array[PackedInt32Array], width: int, height: int, rng: RandomNumberGenerator, difficulty_scale: float) -> void:
	var candidates: Array[Dictionary] = _build_connection_candidates(cells, width, height)
	var extra_connections: int = mini(_count_extra_connections(width, height, difficulty_scale), candidates.size())

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
			var cell: Vector2i = Vector2i(x, y)

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


static func _count_extra_connections(width: int, height: int, difficulty_scale: float) -> int:
	var area: int = width * height
	var ratio: float = clampf(0.05 + float(width + height) / 220.0 + (difficulty_scale - 1.0) * 0.035, 0.05, 0.2)
	return max(1, int(round(float(area) * ratio)))


static func _build_bonuses(
	cells: Array[PackedInt32Array],
	width: int,
	height: int,
	start: Vector2i,
	goal: Vector2i,
	solution_path: Array[Vector2i],
	start_distances: Dictionary,
	goal_distances: Dictionary,
	difficulty_scale: float,
	rng: RandomNumberGenerator
) -> Array[Dictionary]:
	var bonuses: Array[Dictionary] = []
	var bonus_cells: Array[Vector2i] = []
	var optimal_length: int = max(solution_path.size() - 1, 0)

	if optimal_length <= 0:
		return bonuses

	var route_penalty_count: int = clampi(int(floor(float(optimal_length) / 18.0 + maxf(difficulty_scale - 1.0, 0.0) * 0.6)), 0, 3)
	var route_negative_steps: Array[int] = _pick_path_steps(
		optimal_length,
		clampi(int(ceili(float(optimal_length + route_penalty_count * BONUS_VALUE) / float(BONUS_VALUE))), 1, optimal_length - 1),
		rng
	)
	var used_route_steps: Dictionary = {}
	for step_index in route_negative_steps:
		used_route_steps[step_index] = true

	for step_index in route_negative_steps:
		var bonus_cell: Vector2i = solution_path[step_index]
		bonuses.append({
			"cell": bonus_cell,
			"value": -BONUS_VALUE,
		})
		bonus_cells.append(bonus_cell)

	var route_positive_steps: Array[int] = _pick_path_steps(optimal_length, route_penalty_count, rng, used_route_steps)
	for step_index in route_positive_steps:
		used_route_steps[step_index] = true
		var penalty_cell: Vector2i = solution_path[step_index]
		bonuses.append({
			"cell": penalty_cell,
			"value": BONUS_VALUE,
		})
		bonus_cells.append(penalty_cell)

	var route_score: int = optimal_length + route_positive_steps.size() * BONUS_VALUE - route_negative_steps.size() * BONUS_VALUE
	if route_score > 0:
		var extra_negative_steps: Array[int] = _pick_path_steps(optimal_length, int(ceili(float(route_score) / float(BONUS_VALUE))), rng, used_route_steps)
		for step_index in extra_negative_steps:
			used_route_steps[step_index] = true
			var extra_bonus_cell: Vector2i = solution_path[step_index]
			bonuses.append({
				"cell": extra_bonus_cell,
				"value": -BONUS_VALUE,
			})
			bonus_cells.append(extra_bonus_cell)

	var detour_gain_candidates: Array[Dictionary] = []
	var detour_loss_candidates: Array[Dictionary] = []
	var path_lookup: Dictionary = {}
	for path_cell in solution_path:
		path_lookup[path_cell] = true

	for y in range(height):
		for x in range(width):
			var cell: Vector2i = Vector2i(x, y)
			if cell == start or cell == goal or bonus_cells.has(cell):
				continue

			if not start_distances.has(cell) or not goal_distances.has(cell):
				continue

			var detour_cost: int = int(start_distances[cell]) + int(goal_distances[cell]) - optimal_length
			if detour_cost < 1:
				continue

			var candidate: Dictionary = {
				"cell": cell,
				"detour": detour_cost,
			}
			if not path_lookup.has(cell) and detour_cost <= BONUS_VALUE + 1:
				detour_loss_candidates.append(candidate)
			if not path_lookup.has(cell):
				detour_gain_candidates.append(candidate)

	detour_loss_candidates.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return int(a["detour"]) < int(b["detour"])
	)
	detour_gain_candidates.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return int(a["detour"]) > int(b["detour"])
	)

	var detour_loss_limit: int = mini(detour_loss_candidates.size(), clampi(route_penalty_count + int(round(maxf(difficulty_scale - 1.0, 0.0))), 1, 4))
	for candidate_variant in detour_loss_candidates:
		if detour_loss_limit <= 0:
			break

		var candidate: Dictionary = candidate_variant
		var cell: Vector2i = candidate["cell"]
		if not _is_bonus_far_enough(cell, bonus_cells):
			continue

		bonuses.append({
			"cell": cell,
			"value": -BONUS_VALUE,
		})
		bonus_cells.append(cell)
		detour_loss_limit -= 1

	var detour_gain_limit: int = mini(detour_gain_candidates.size(), maxi(2, int(round(float(route_negative_steps.size()) * 0.7)) + int(round(maxf(difficulty_scale - 1.0, 0.0) * 2.0))))
	for candidate_variant in detour_gain_candidates:
		if detour_gain_limit <= 0:
			break

		var candidate: Dictionary = candidate_variant
		var cell: Vector2i = candidate["cell"]
		if not _is_bonus_far_enough(cell, bonus_cells):
			continue

		bonuses.append({
			"cell": cell,
			"value": BONUS_VALUE,
		})
		bonus_cells.append(cell)
		detour_gain_limit -= 1

	return bonuses
static func _pick_path_steps(optimal_length: int, count: int, rng: RandomNumberGenerator, excluded_steps: Dictionary = {}) -> Array[int]:
	var candidates: Array[int] = []
	for step_index in range(1, optimal_length):
		if excluded_steps.has(step_index):
			continue
		candidates.append(step_index)

	for index in range(candidates.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var temp: int = candidates[index]
		candidates[index] = candidates[swap_index]
		candidates[swap_index] = temp

	var selected: Array[int] = []
	for step_index in candidates:
		var is_far_enough: bool = true
		for existing_step in selected:
			if absi(step_index - existing_step) < 2:
				is_far_enough = false
				break
		if not is_far_enough:
			continue
		selected.append(step_index)
		if selected.size() >= count:
			selected.sort()
			return selected

	for step_index in candidates:
		if selected.has(step_index):
			continue
		selected.append(step_index)
		if selected.size() >= count:
			break

	selected.sort()
	return selected


static func _is_bonus_far_enough(cell: Vector2i, existing_bonus_cells: Array[Vector2i]) -> bool:
	for existing_cell in existing_bonus_cells:
		var manhattan_distance: int = absi(cell.x - existing_cell.x) + absi(cell.y - existing_cell.y)
		if manhattan_distance < 3:
			return false
	return true


static func _add_connection(cells: Array[PackedInt32Array], cell: Vector2i, dir_index: int) -> void:
	var next_cell: Vector2i = cell + DIRS[dir_index]
	cells[cell.y][cell.x] |= DIR_BITS[dir_index]
	cells[next_cell.y][next_cell.x] |= OPPOSITE_BITS[dir_index]


static func _find_farthest(cells: Array[PackedInt32Array], width: int, height: int, start: Vector2i) -> Dictionary:
	var bfs: Dictionary = _bfs(cells, width, height, start)
	var distances: Dictionary = bfs["distances"]
	var farthest: Vector2i = start

	for candidate_variant in distances.keys():
		var candidate: Vector2i = candidate_variant
		if int(distances[candidate]) > int(distances[farthest]):
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
	var index: int = 0

	while index < queue.size():
		var current: Vector2i = queue[index]
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
	var current: Vector2i = goal

	while current != start and previous.has(current):
		current = previous[current]
		path.append(current)

	path.reverse()
	return path


static func _is_inside(cell: Vector2i, width: int, height: int) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height
