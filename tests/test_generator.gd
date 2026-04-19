extends RefCounted

const GeneratorScript = preload("res://scripts/maze_generator.gd")


func run() -> Dictionary:
	var failures: Array[String] = []
	var assertions: int = 0
	var generated = GeneratorScript.generate(5, 5, 123456, 1.15)

	assertions += 1
	if generated == null:
		failures.append("generator should produce a puzzle for a normal 5x5 request")
		return {
			"assertions": assertions,
			"failures": failures,
		}

	var path: Array[Vector2i] = generated.solution_path

	assertions += 1
	if generated.start == generated.goal:
		failures.append("generated start and goal should differ")

	assertions += 1
	if generated.target_total <= 0:
		failures.append("generated puzzles should have a positive target total")

	assertions += 1
	if path.is_empty() or path[0] != generated.start:
		failures.append("solution paths should begin at the start cell")

	assertions += 1
	if path.is_empty() or path[path.size() - 1] != generated.goal:
		failures.append("solution paths should end at the goal cell")

	assertions += 1
	if generated.solution_length != max(path.size() - 1, 0):
		failures.append("solution length metadata should match the stored path")

	assertions += 1
	if generated.cell_values.size() != 5:
		failures.append("generated puzzles should return one value row per grid row")

	return {
		"assertions": assertions,
		"failures": failures,
	}
