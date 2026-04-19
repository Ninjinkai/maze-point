extends RefCounted
class_name MazeGenerator

const DIRS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
const MAX_GENERATION_ATTEMPTS := 220
const MAX_PATH_SEARCH_ATTEMPTS := 48


static func generate(width: int, height: int, seed: int, difficulty_scale: float = 1.0) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed

	for _attempt in range(MAX_GENERATION_ATTEMPTS):
		var candidate: Dictionary = _build_candidate(width, height, rng, difficulty_scale)
		if not candidate.is_empty():
			return candidate

	return _build_fallback_candidate(width, height, rng, difficulty_scale)


static func orthogonal_neighbors(width: int, height: int, cell: Vector2i) -> Array[Vector2i]:
	var results: Array[Vector2i] = []
	for direction in DIRS:
		var neighbor: Vector2i = cell + direction
		if is_inside(neighbor, width, height):
			results.append(neighbor)
	return results


static func is_inside(cell: Vector2i, width: int, height: int) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


static func _build_candidate(width: int, height: int, rng: RandomNumberGenerator, difficulty_scale: float) -> Dictionary:
	var endpoints: Dictionary = _pick_start_and_goal(width, height, rng)
	if endpoints.is_empty():
		return {}

	var start: Vector2i = endpoints["start"]
	var goal: Vector2i = endpoints["goal"]
	var minimum_moves: int = _manhattan_distance(start, goal)
	var maximum_moves: int = mini(width * height - 1, minimum_moves + _detour_budget(width, height, difficulty_scale))
	if maximum_moves < minimum_moves:
		return {}

	var move_options: Array[int] = []
	for moves in range(minimum_moves, maximum_moves + 1):
		if ((moves - minimum_moves) % 2) == 0:
			move_options.append(moves)
	if move_options.is_empty():
		return {}

	for index in range(move_options.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var temp: int = move_options[index]
		move_options[index] = move_options[swap_index]
		move_options[swap_index] = temp

	for desired_moves in move_options:
		var intended_path: Array[Vector2i] = _find_random_path(width, height, start, goal, desired_moves, rng)
		if intended_path.is_empty():
			continue

		var values: Array[PackedInt32Array] = _build_values(width, height, intended_path, goal, rng, difficulty_scale)
		var target_total: int = _sum_path_total(values, intended_path, goal)
		if target_total <= 0:
			continue

		var solution_summary: Dictionary = _find_unique_optimal_solution(values, width, height, start, goal, target_total, desired_moves)
		if solution_summary.is_empty():
			continue

		return {
			"cell_values": values,
			"start": start,
			"goal": goal,
			"target_total": target_total,
			"solution_path": solution_summary["path"],
			"solution_length": solution_summary["steps"],
			"max_cell_value": _get_max_cell_value(difficulty_scale),
		}

	return {}


static func _build_fallback_candidate(width: int, height: int, rng: RandomNumberGenerator, difficulty_scale: float) -> Dictionary:
	var start: Vector2i = Vector2i(0, height / 2)
	var goal: Vector2i = Vector2i(width - 1, height / 2)
	if start == goal:
		goal = Vector2i(width - 1, mini(height - 1, start.y + 1))

	var path: Array[Vector2i] = []
	var current: Vector2i = start
	path.append(current)
	while current != goal:
		current += Vector2i.RIGHT if current.x < goal.x else Vector2i.LEFT
		path.append(current)

	var values: Array[PackedInt32Array] = _build_empty_values(width, height)
	var path_lookup: Dictionary = {}
	for cell in path:
		path_lookup[cell] = true

	for y in range(height):
		for x in range(width):
			var cell: Vector2i = Vector2i(x, y)
			if cell == goal:
				values[y][x] = 0
			elif path_lookup.has(cell):
				values[y][x] = clampi(2 + int(round(difficulty_scale * 1.6)) + ((x + y) % 2), 1, 9)
			else:
				values[y][x] = 1

	var target_total: int = _sum_path_total(values, path, goal)
	return {
		"cell_values": values,
		"start": start,
		"goal": goal,
		"target_total": target_total,
		"solution_path": path,
		"solution_length": max(path.size() - 1, 0),
		"max_cell_value": _get_max_cell_value(difficulty_scale),
	}


static func _pick_start_and_goal(width: int, height: int, rng: RandomNumberGenerator) -> Dictionary:
	var max_distance: int = width + height - 2
	var minimum_distance: int = maxi(3, int(round(float(max_distance) * 0.62)))
	var best_start: Vector2i = Vector2i.ZERO
	var best_goal: Vector2i = Vector2i.ZERO
	var best_distance: int = -1
	for _attempt in range(64):
		var start: Vector2i = Vector2i(rng.randi_range(0, width - 1), rng.randi_range(0, height - 1))
		var goal: Vector2i = Vector2i(rng.randi_range(0, width - 1), rng.randi_range(0, height - 1))
		if goal == start:
			continue
		var distance: int = _manhattan_distance(start, goal)
		if distance > best_distance:
			best_distance = distance
			best_start = start
			best_goal = goal
		if distance < minimum_distance:
			continue
		return {
			"start": start,
			"goal": goal,
		}
	if best_distance >= 2:
		return {
			"start": best_start,
			"goal": best_goal,
		}
	return {}


static func _detour_budget(width: int, height: int, difficulty_scale: float) -> int:
	var area: int = width * height
	var raw_budget: int = clampi(2 + int(round(difficulty_scale * 1.1)) + int(round(float(area) / 16.0)), 2, maxi(2, area / 3))
	if raw_budget % 2 != 0:
		raw_budget -= 1
	return maxi(raw_budget, 0)


static func _find_random_path(width: int, height: int, start: Vector2i, goal: Vector2i, desired_moves: int, rng: RandomNumberGenerator) -> Array[Vector2i]:
	for _attempt in range(MAX_PATH_SEARCH_ATTEMPTS):
		var visited: Dictionary = {start: true}
		var path: Array[Vector2i] = [start]
		if _extend_path(width, height, goal, desired_moves, rng, path, visited):
			return path
	return []


static func _extend_path(width: int, height: int, goal: Vector2i, desired_moves: int, rng: RandomNumberGenerator, path: Array[Vector2i], visited: Dictionary) -> bool:
	var current: Vector2i = path[path.size() - 1]
	var moves_used: int = path.size() - 1
	if moves_used == desired_moves:
		return current == goal

	var remaining_moves: int = desired_moves - moves_used
	var neighbors: Array[Vector2i] = orthogonal_neighbors(width, height, current)
	for index in range(neighbors.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var temp: Vector2i = neighbors[index]
		neighbors[index] = neighbors[swap_index]
		neighbors[swap_index] = temp

	neighbors.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _manhattan_distance(a, goal) < _manhattan_distance(b, goal)
	)

	for neighbor in neighbors:
		if visited.has(neighbor):
			continue

		var distance_to_goal: int = _manhattan_distance(neighbor, goal)
		if distance_to_goal > remaining_moves - 1:
			continue
		if ((remaining_moves - 1 - distance_to_goal) % 2) != 0:
			continue

		visited[neighbor] = true
		path.append(neighbor)
		if _extend_path(width, height, goal, desired_moves, rng, path, visited):
			return true
		path.pop_back()
		visited.erase(neighbor)

	return false


static func _build_values(width: int, height: int, path: Array[Vector2i], goal: Vector2i, rng: RandomNumberGenerator, difficulty_scale: float) -> Array[PackedInt32Array]:
	var values: Array[PackedInt32Array] = _build_empty_values(width, height)
	var path_lookup: Dictionary = {}
	for cell in path:
		path_lookup[cell] = true

	var max_value: int = _get_max_cell_value(difficulty_scale)
	var off_path_max: int = maxi(2, max_value - 3)
	var path_min: int = mini(max_value, maxi(1, 1 + int(floor(difficulty_scale * 0.65))))
	var path_band: int = maxi(2, 2 + int(round(difficulty_scale * 0.6)))
	var off_path_bias: int = mini(off_path_max, 2 + int(round(difficulty_scale * 0.35)))

	for y in range(height):
		for x in range(width):
			var cell: Vector2i = Vector2i(x, y)
			if cell == goal:
				values[y][x] = 0
			elif path_lookup.has(cell):
				values[y][x] = rng.randi_range(path_min, mini(max_value, path_min + path_band))
			else:
				values[y][x] = rng.randi_range(1, off_path_max)
				if rng.randf() < 0.65:
					values[y][x] = mini(values[y][x], off_path_bias)

	return values


static func _build_empty_values(width: int, height: int) -> Array[PackedInt32Array]:
	var values: Array[PackedInt32Array] = []
	for _y in range(height):
		var row: PackedInt32Array = PackedInt32Array()
		row.resize(width)
		values.append(row)
	return values


static func _get_max_cell_value(difficulty_scale: float) -> int:
	return clampi(4 + int(round(difficulty_scale * 1.25)), 4, 8)


static func _sum_path_total(values: Array[PackedInt32Array], path: Array[Vector2i], goal: Vector2i) -> int:
	var total: int = 0
	for index in range(1, path.size()):
		var cell: Vector2i = path[index]
		if cell == goal:
			continue
		total += values[cell.y][cell.x]
	return total


static func _find_unique_optimal_solution(values: Array[PackedInt32Array], width: int, height: int, start: Vector2i, goal: Vector2i, target_total: int, desired_moves: int) -> Dictionary:
	var current_states: Dictionary = {start: {0: 1}}

	for step in range(1, desired_moves + 1):
		var next_states: Dictionary = {}
		for cell_variant in current_states.keys():
			var cell: Vector2i = cell_variant
			var totals: Dictionary = current_states[cell]
			for neighbor in orthogonal_neighbors(width, height, cell):
				var added_value: int = 0 if neighbor == goal else values[neighbor.y][neighbor.x]
				if not next_states.has(neighbor):
					next_states[neighbor] = {}
				var destination_totals: Dictionary = next_states[neighbor]
				for total_variant in totals.keys():
					var current_total: int = int(total_variant)
					var next_total: int = current_total + added_value
					if next_total > target_total:
						continue
					var current_count: int = int(destination_totals.get(next_total, 0))
					destination_totals[next_total] = mini(2, current_count + int(totals[total_variant]))

		current_states = next_states
		if not current_states.has(goal):
			continue

		var goal_totals: Dictionary = current_states[goal]
		if not goal_totals.has(target_total):
			continue

		if int(goal_totals[target_total]) != 1:
			return {}
		if step != desired_moves:
			return {}

		var solved_path: Array[Vector2i] = _recover_solution_path(values, width, height, start, goal, target_total, step)
		if solved_path.is_empty():
			return {}

		return {
			"path": solved_path,
			"steps": step,
		}

	return {}


static func _recover_solution_path(values: Array[PackedInt32Array], width: int, height: int, start: Vector2i, goal: Vector2i, target_total: int, step_limit: int) -> Array[Vector2i]:
	var path: Array[Vector2i] = [start]
	if _search_solution_path(values, width, height, goal, target_total, step_limit, 0, path):
		return path
	return []


static func _search_solution_path(values: Array[PackedInt32Array], width: int, height: int, goal: Vector2i, target_total: int, step_limit: int, running_total: int, path: Array[Vector2i]) -> bool:
	var current: Vector2i = path[path.size() - 1]
	var moves_used: int = path.size() - 1
	if moves_used == step_limit:
		return current == goal and running_total == target_total

	var remaining_moves: int = step_limit - moves_used
	for neighbor in orthogonal_neighbors(width, height, current):
		var added_value: int = 0 if neighbor == goal else values[neighbor.y][neighbor.x]
		var next_total: int = running_total + added_value
		if next_total > target_total:
			continue
		var distance_to_goal: int = _manhattan_distance(neighbor, goal)
		if distance_to_goal > remaining_moves - 1:
			continue
		if distance_to_goal == 0 and next_total != target_total and remaining_moves == 1:
			continue

		path.append(neighbor)
		if _search_solution_path(values, width, height, goal, target_total, step_limit, next_total, path):
			return true
		path.pop_back()

	return false


static func _manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
