extends RefCounted

const PlayfieldUtilsScript = preload("res://scripts/game/game_playfield_utils.gd")


func run() -> Dictionary:
	var failures: Array[String] = []
	var assertions: int = 0
	var draw_area := PlayfieldUtilsScript.get_draw_area(Vector2(1080, 1920), 12.0, 180.0, 150.0)
	var cell_size := PlayfieldUtilsScript.get_cell_size(draw_area, 4, 5)
	var origin := PlayfieldUtilsScript.get_grid_origin(draw_area, 4, 5, cell_size)
	var values: Array[PackedInt32Array] = [PackedInt32Array([1, 2]), PackedInt32Array([3, 4])]

	assertions += 1
	if draw_area.position != Vector2(12.0, 180.0):
		failures.append("draw area should start below the top HUD with the outer margin applied")

	assertions += 1
	if round(cell_size) != 264:
		failures.append("cell size should fit the tighter grid axis")

	assertions += 1
	if origin.y <= draw_area.position.y:
		failures.append("grid origin should center shorter grids inside the draw area")

	assertions += 1
	if PlayfieldUtilsScript.cell_to_screen(origin, cell_size, Vector2(1, 1)) == Vector2.ZERO:
		failures.append("cell-to-screen conversion should produce a usable point")

	assertions += 1
	if PlayfieldUtilsScript.get_tap_radius(cell_size) < 34.0:
		failures.append("tap radius should never fall below the minimum")

	assertions += 1
	if PlayfieldUtilsScript.get_cell_value(values, Vector2i(1, 1)) != 4:
		failures.append("cell-value lookup should read from packed rows correctly")

	assertions += 1
	if PlayfieldUtilsScript.with_alpha(Color.RED, 0.25).a != 0.25:
		failures.append("alpha helper should preserve the requested transparency")

	return {
		"assertions": assertions,
		"failures": failures,
	}
