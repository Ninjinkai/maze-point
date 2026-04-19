extends RefCounted
class_name MazeGeneratorMetrics

static func score_endpoint_pair(start: Vector2i, goal: Vector2i) -> float:
	var delta_x: int = absi(start.x - goal.x)
	var delta_y: int = absi(start.y - goal.y)
	var distance: int = delta_x + delta_y
	var balance_bonus: float = float(mini(delta_x, delta_y)) * 2.2
	var axis_penalty: float = 2.8 if delta_x == 0 or delta_y == 0 else 0.0
	return float(distance) * 2.0 + balance_bonus - axis_penalty


static func score_path_neighbor(neighbor: Vector2i, current: Vector2i, goal: Vector2i, previous_direction: Vector2i, remaining_moves: int, width: int, height: int, neighbor_count: int) -> float:
	var next_direction: Vector2i = neighbor - current
	var distance_score: float = float(width + height - manhattan_distance(neighbor, goal)) * 2.6
	var turn_bonus: float = 0.0
	if previous_direction != Vector2i.ZERO and next_direction != previous_direction:
		turn_bonus = 3.8
	elif previous_direction != Vector2i.ZERO:
		turn_bonus = -1.4
	var center: Vector2 = Vector2((width - 1) * 0.5, (height - 1) * 0.5)
	var center_distance: float = Vector2(neighbor).distance_to(center)
	var center_bonus: float = maxf(0.0, 2.4 - center_distance * 0.55)
	var flexibility_bonus: float = float(neighbor_count) * 0.35
	var detour_bonus: float = clampf(float(remaining_moves - manhattan_distance(neighbor, goal)), 0.0, 8.0) * 0.12
	return distance_score + turn_bonus + center_bonus + flexibility_bonus + detour_bonus


static func path_has_shape_variety(path: Array[Vector2i], start: Vector2i, goal: Vector2i) -> bool:
	var move_count: int = max(path.size() - 1, 0)
	if move_count <= 2:
		return true
	var delta_x: int = absi(start.x - goal.x)
	var delta_y: int = absi(start.y - goal.y)
	var turn_count: int = count_path_turns(path)
	var minimum_turns: int = 1 if move_count >= 4 else 0
	if move_count >= 7:
		minimum_turns = 2
	if mini(delta_x, delta_y) >= 2:
		minimum_turns = maxi(minimum_turns, 2)
	var longest_straight_run: int = get_longest_straight_run(path)
	var straight_run_limit: int = maxi(3, int(ceili(float(move_count) * 0.45)))
	if move_count >= 8:
		straight_run_limit = mini(straight_run_limit, 4)
	return turn_count >= minimum_turns and longest_straight_run <= straight_run_limit


static func count_path_turns(path: Array[Vector2i]) -> int:
	var turns: int = 0
	for index in range(2, path.size()):
		var previous_direction: Vector2i = path[index - 1] - path[index - 2]
		var next_direction: Vector2i = path[index] - path[index - 1]
		if previous_direction != next_direction:
			turns += 1
	return turns


static func get_longest_straight_run(path: Array[Vector2i]) -> int:
	var longest_run: int = 1
	var current_run: int = 1
	var previous_direction: Vector2i = Vector2i.ZERO
	for index in range(1, path.size()):
		var direction: Vector2i = path[index] - path[index - 1]
		if index == 1 or direction == previous_direction:
			current_run += 1
		else:
			current_run = 2
		previous_direction = direction
		longest_run = maxi(longest_run, current_run)
	return longest_run - 1


static func manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
