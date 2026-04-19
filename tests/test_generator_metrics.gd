extends RefCounted

const MetricsScript = preload("res://scripts/generator/maze_generator_metrics.gd")


func run() -> Dictionary:
	var failures: Array[String] = []
	var assertions: int = 0
	var varied_path: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(1, 1),
		Vector2i(2, 1),
		Vector2i(2, 2),
	]
	var straight_path: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(3, 0),
		Vector2i(4, 0),
	]

	assertions += 1
	if MetricsScript.score_endpoint_pair(Vector2i(0, 0), Vector2i(4, 4)) <= MetricsScript.score_endpoint_pair(Vector2i(0, 0), Vector2i(4, 0)):
		failures.append("balanced endpoint pairs should score higher than axis-aligned ones")

	assertions += 1
	if MetricsScript.count_path_turns(varied_path) != 3:
		failures.append("turn counting should match the path geometry")

	assertions += 1
	if MetricsScript.get_longest_straight_run(straight_path) != 4:
		failures.append("straight-run counting should track the longest segment")

	assertions += 1
	if not MetricsScript.path_has_shape_variety(varied_path, varied_path[0], varied_path[varied_path.size() - 1]):
		failures.append("turn-heavy paths should pass the variety gate")

	assertions += 1
	if MetricsScript.path_has_shape_variety(straight_path, straight_path[0], straight_path[straight_path.size() - 1]):
		failures.append("overly straight paths should fail the variety gate")

	assertions += 1
	var turning_score := MetricsScript.score_path_neighbor(Vector2i(1, 2), Vector2i(1, 1), Vector2i(3, 3), Vector2i.RIGHT, 5, 5, 5, 4)
	var straight_score := MetricsScript.score_path_neighbor(Vector2i(2, 1), Vector2i(1, 1), Vector2i(3, 3), Vector2i.RIGHT, 5, 5, 5, 4)
	if turning_score <= straight_score:
		failures.append("neighbor scoring should reward helpful turns")

	return {
		"assertions": assertions,
		"failures": failures,
	}
