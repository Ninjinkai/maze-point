extends RefCounted

const GeneratorScript = preload("res://scripts/maze_generator.gd")


func run() -> Dictionary:
	var failures: Array[String] = []
	var assertions: int = 0
	var generated: Dictionary = GeneratorScript.generate(5, 5, 123456, 1.15)
	var path: Array[Vector2i] = generated.get("solution_path", [])

	assertions += 1
	if generated.is_empty():
		failures.append("generator should produce a puzzle for a normal 5x5 request")
		return {
			"assertions": assertions,
			"failures": failures,
		}

	assertions += 1
	if generated.get("start", Vector2i.ZERO) == generated.get("goal", Vector2i.ZERO):
		failures.append("generated start and goal should differ")

	assertions += 1
	if int(generated.get("target_total", 0)) <= 0:
		failures.append("generated puzzles should have a positive target total")

	assertions += 1
	if path.is_empty() or path[0] != generated.get("start", Vector2i.ZERO):
		failures.append("solution paths should begin at the start cell")

	assertions += 1
	if path.is_empty() or path[path.size() - 1] != generated.get("goal", Vector2i.ZERO):
		failures.append("solution paths should end at the goal cell")

	assertions += 1
	if int(generated.get("solution_length", -1)) != max(path.size() - 1, 0):
		failures.append("solution length metadata should match the stored path")

	assertions += 1
	var values: Array = generated.get("cell_values", [])
	if values.size() != 5:
		failures.append("generated puzzles should return one value row per grid row")

	return {
		"assertions": assertions,
		"failures": failures,
	}
