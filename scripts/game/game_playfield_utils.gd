extends RefCounted
class_name MazePointPlayfieldUtils

static func get_draw_area(viewport_size: Vector2, outer_margin: float, top_hud_height: float, bottom_hud_height: float) -> Rect2:
	return Rect2(
		Vector2(outer_margin, top_hud_height),
		viewport_size - Vector2(outer_margin * 2.0, top_hud_height + bottom_hud_height)
	)


static func get_cell_size(draw_area: Rect2, grid_width: int, grid_height: int) -> float:
	return minf(draw_area.size.x / float(grid_width), draw_area.size.y / float(grid_height))


static func get_grid_origin(draw_area: Rect2, grid_width: int, grid_height: int, cell_size: float) -> Vector2:
	var grid_size: Vector2 = Vector2(grid_width, grid_height) * cell_size
	return draw_area.position + (draw_area.size - grid_size) * 0.5


static func cell_to_screen(origin: Vector2, cell_size: float, cell: Vector2) -> Vector2:
	return origin + (cell + Vector2.ONE * 0.5) * cell_size


static func get_tap_radius(cell_size: float) -> float:
	return maxf(cell_size * 0.42, 34.0)


static func get_cell_value(cell_values: Array[PackedInt32Array], cell: Vector2i) -> int:
	return int(cell_values[cell.y][cell.x])


static func with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)
