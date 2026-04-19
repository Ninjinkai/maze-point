extends RefCounted
class_name MazePuzzleData

var cell_values: Array[PackedInt32Array]
var start: Vector2i
var goal: Vector2i
var target_total: int
var solution_path: Array[Vector2i]
var solution_length: int
var max_cell_value: int


func _init(
	in_cell_values: Array[PackedInt32Array],
	in_start: Vector2i,
	in_goal: Vector2i,
	in_target_total: int,
	in_solution_path: Array[Vector2i],
	in_solution_length: int,
	in_max_cell_value: int
) -> void:
	cell_values = in_cell_values
	start = in_start
	goal = in_goal
	target_total = in_target_total
	solution_path = in_solution_path
	solution_length = in_solution_length
	max_cell_value = in_max_cell_value
