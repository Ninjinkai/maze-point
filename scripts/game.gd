extends Node2D

const MazeGeneratorScript = preload("res://scripts/maze_generator.gd")
const BACKGROUND_COLOR := Color("101826")
const PLAYFIELD_COLOR := Color("162233")
const MAZE_COLOR := Color("4d6685")
const NODE_COLOR := Color("d8e4f4")
const START_COLOR := Color("5fd08c")
const GOAL_COLOR := Color("ffcc66")
const PLAYER_COLOR := Color("73d2ff")
const PATH_COLOR := Color("65f2c2")
const HINT_COLOR := Color("b485ff")
const TEXT_COLOR := Color("f5f7fb")
const TOP_HUD_HEIGHT := 168.0
const BOTTOM_HUD_HEIGHT := 176.0
const OUTER_MARGIN := 24.0

var run_seed := 0
var level := 1
var maze_width := 0
var maze_height := 0
var level_seed := 0
var cells: Array[PackedInt32Array] = []
var start_cell := Vector2i.ZERO
var goal_cell := Vector2i.ZERO
var player_cell := Vector2i.ZERO
var player_path: Array[Vector2i] = []
var solution_path: Array[Vector2i] = []
var hint_path: Array[Vector2i] = []
var goal_previous := {}
var completed := false
var pulse_time := 0.0

var level_label: Label
var details_label: Label
var prompt_label: Label
var status_label: Label
var action_button: Button
var retry_button: Button
var new_run_button: Button


func _ready() -> void:
	randomize()
	_build_ui()
	_start_new_run()


func _process(delta: float) -> void:
	pulse_time += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_maze_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_maze_tap(event.position)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), BACKGROUND_COLOR, true)

	if maze_width <= 0 or maze_height <= 0:
		return

	var draw_area := _get_draw_area()
	draw_rect(draw_area, PLAYFIELD_COLOR, true)

	var spacing := _get_spacing()
	var origin := _get_origin(spacing)
	var maze_line_width := clampf(spacing * 0.17, 3.0, 10.0)
	var trail_width := clampf(spacing * 0.24, 5.0, 14.0)
	var node_radius := clampf(spacing * 0.14, 3.5, 9.0)
	var major_radius := clampf(spacing * 0.26, 7.0, 15.0)
	var pulse := 0.82 + 0.18 * sin(pulse_time * 4.2)

	for y in range(maze_height):
		for x in range(maze_width):
			var cell := Vector2i(x, y)
			var cell_pos := origin + Vector2(x, y) * spacing

			if MazeGeneratorScript.has_connection(cells, cell, Vector2i.RIGHT) and x + 1 < maze_width:
				draw_line(cell_pos, origin + Vector2(x + 1, y) * spacing, MAZE_COLOR, maze_line_width)
			if MazeGeneratorScript.has_connection(cells, cell, Vector2i.DOWN) and y + 1 < maze_height:
				draw_line(cell_pos, origin + Vector2(x, y + 1) * spacing, MAZE_COLOR, maze_line_width)

	for i in range(player_path.size() - 1):
		draw_line(_cell_to_screen(player_path[i]), _cell_to_screen(player_path[i + 1]), PATH_COLOR, trail_width)

	if hint_path.size() > 1:
		for i in range(hint_path.size() - 1):
			draw_line(_cell_to_screen(hint_path[i]), _cell_to_screen(hint_path[i + 1]), HINT_COLOR, maze_line_width)

	for y in range(maze_height):
		for x in range(maze_width):
			draw_circle(origin + Vector2(x, y) * spacing, node_radius, NODE_COLOR)

	draw_circle(_cell_to_screen(start_cell), major_radius * 0.9, START_COLOR)
	draw_circle(_cell_to_screen(goal_cell), major_radius, GOAL_COLOR)
	draw_arc(_cell_to_screen(goal_cell), major_radius + 7.0 + pulse * 4.0, 0.0, TAU, 48, GOAL_COLOR.lightened(0.25), 3.5)

	for neighbor in MazeGeneratorScript.connected_neighbors(cells, maze_width, maze_height, player_cell):
		var highlight_radius := minf(_get_tap_radius(), spacing * 0.48) * pulse
		draw_circle(_cell_to_screen(neighbor), highlight_radius, HINT_COLOR.darkened(0.15))
		draw_circle(_cell_to_screen(neighbor), highlight_radius * 0.45, NODE_COLOR)

	draw_circle(_cell_to_screen(player_cell), major_radius, PLAYER_COLOR)
	draw_arc(_cell_to_screen(player_cell), major_radius + 8.0 + pulse * 4.0, 0.0, TAU, 48, PLAYER_COLOR.lightened(0.2), 3.5)


func _start_new_run() -> void:
	run_seed = randi()
	level = 1
	_generate_level()


func _restart_level() -> void:
	_generate_level()


func _generate_level() -> void:
	var dimensions := _get_level_dimensions(level)
	maze_width = dimensions.x
	maze_height = dimensions.y
	level_seed = abs(hash([run_seed, level, maze_width, maze_height]))
	if level_seed == 0:
		level_seed = 1

	var maze: Dictionary = MazeGeneratorScript.generate(maze_width, maze_height, level_seed)
	cells = maze["cells"]
	start_cell = maze["start"]
	goal_cell = maze["goal"]
	player_cell = start_cell
	player_path = [start_cell]
	solution_path = maze["solution_path"]
	hint_path = []
	goal_previous = maze["goal_previous"]
	completed = false
	_update_ui()
	queue_redraw()


func _get_level_dimensions(current_level: int) -> Vector2i:
	var base_size := 4 + current_level
	return Vector2i(base_size + int(current_level / 3), base_size + int(current_level / 4))


func _handle_maze_tap(screen_position: Vector2) -> void:
	if completed:
		return

	var tapped_cell := _find_tapped_neighbor(screen_position)
	if tapped_cell.x < 0:
		return

	_move_player_to(tapped_cell)


func _find_tapped_neighbor(screen_position: Vector2) -> Vector2i:
	var best_cell := Vector2i(-1, -1)
	var best_distance := INF

	for neighbor in MazeGeneratorScript.connected_neighbors(cells, maze_width, maze_height, player_cell):
		var distance := screen_position.distance_to(_cell_to_screen(neighbor))
		if distance > _get_tap_radius():
			continue
		if distance < best_distance:
			best_distance = distance
			best_cell = neighbor

	return best_cell


func _move_player_to(target_cell: Vector2i) -> void:
	hint_path = []

	if player_path.size() > 1 and target_cell == player_path[player_path.size() - 2]:
		player_path.pop_back()
	else:
		player_path.append(target_cell)

	player_cell = target_cell

	if player_cell == goal_cell:
		completed = true

	_update_ui()
	queue_redraw()


func _show_hint_or_advance() -> void:
	if completed:
		level += 1
		_generate_level()
		return

	hint_path = _build_path_to_goal(player_cell)
	status_label.text = "Hint revealed. Follow the violet path toward the goal."
	queue_redraw()


func _build_path_to_goal(origin_cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = [origin_cell]
	var current := origin_cell

	while current != goal_cell and goal_previous.has(current):
		current = goal_previous[current]
		result.append(current)

	return result


func _update_ui() -> void:
	var path_length: int = max(solution_path.size() - 1, 0)
	level_label.text = "Maze %d" % level
	details_label.text = "%dx%d grid  |  best path %d steps  |  seed %d" % [maze_width, maze_height, path_length, level_seed]
	prompt_label.text = "Tap one of the glowing neighboring nodes to move. Reach the gold node to unlock the next maze."

	if completed:
		status_label.text = "Maze cleared in %d taps. The next maze grows larger and trickier." % max(player_path.size() - 1, 0)
		action_button.text = "Next Maze"
	else:
		status_label.text = "Current path: %d taps  |  Remaining shortest path: %d" % [
			max(player_path.size() - 1, 0),
			max(_build_path_to_goal(player_cell).size() - 1, 0),
		]
		action_button.text = "Hint"


func _get_draw_area() -> Rect2:
	var viewport_size := get_viewport_rect().size
	return Rect2(
		Vector2(OUTER_MARGIN, TOP_HUD_HEIGHT),
		viewport_size - Vector2(OUTER_MARGIN * 2.0, TOP_HUD_HEIGHT + BOTTOM_HUD_HEIGHT)
	)


func _get_spacing() -> float:
	var draw_area := _get_draw_area()
	var horizontal_steps: int = max(maze_width - 1, 1)
	var vertical_steps: int = max(maze_height - 1, 1)
	return minf(draw_area.size.x / float(horizontal_steps), draw_area.size.y / float(vertical_steps))


func _get_origin(spacing: float) -> Vector2:
	var draw_area := _get_draw_area()
	var grid_size := Vector2(max(maze_width - 1, 0), max(maze_height - 1, 0)) * spacing
	return draw_area.position + (draw_area.size - grid_size) * 0.5


func _cell_to_screen(cell: Vector2i) -> Vector2:
	var spacing := _get_spacing()
	return _get_origin(spacing) + Vector2(cell.x, cell.y) * spacing


func _get_tap_radius() -> float:
	return maxf(_get_spacing() * 0.55, 34.0)


func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)

	var top_panel := PanelContainer.new()
	top_panel.anchor_right = 1.0
	top_panel.offset_left = 16.0
	top_panel.offset_top = 16.0
	top_panel.offset_right = -16.0
	top_panel.offset_bottom = TOP_HUD_HEIGHT - 16.0
	top_panel.add_theme_stylebox_override("panel", _make_panel_style(Color("203147"), Color("314864")))
	ui.add_child(top_panel)

	var top_content := VBoxContainer.new()
	top_content.add_theme_constant_override("separation", 6)
	top_panel.add_child(top_content)

	level_label = Label.new()
	level_label.add_theme_font_size_override("font_size", 34)
	level_label.add_theme_color_override("font_color", TEXT_COLOR)
	top_content.add_child(level_label)

	details_label = Label.new()
	details_label.add_theme_font_size_override("font_size", 21)
	details_label.add_theme_color_override("font_color", TEXT_COLOR)
	top_content.add_child(details_label)

	prompt_label = Label.new()
	prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt_label.add_theme_font_size_override("font_size", 20)
	prompt_label.add_theme_color_override("font_color", TEXT_COLOR)
	top_content.add_child(prompt_label)

	var bottom_panel := PanelContainer.new()
	bottom_panel.anchor_top = 1.0
	bottom_panel.anchor_right = 1.0
	bottom_panel.anchor_bottom = 1.0
	bottom_panel.offset_left = 16.0
	bottom_panel.offset_top = -BOTTOM_HUD_HEIGHT + 16.0
	bottom_panel.offset_right = -16.0
	bottom_panel.offset_bottom = -16.0
	bottom_panel.add_theme_stylebox_override("panel", _make_panel_style(Color("203147"), Color("314864")))
	ui.add_child(bottom_panel)

	var bottom_content := VBoxContainer.new()
	bottom_content.add_theme_constant_override("separation", 12)
	bottom_panel.add_child(bottom_content)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 22)
	status_label.add_theme_color_override("font_color", TEXT_COLOR)
	bottom_content.add_child(status_label)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	bottom_content.add_child(buttons)

	action_button = _make_button("Hint")
	action_button.pressed.connect(_show_hint_or_advance)
	buttons.add_child(action_button)

	retry_button = _make_button("Retry")
	retry_button.pressed.connect(_restart_level)
	buttons.add_child(retry_button)

	new_run_button = _make_button("New Run")
	new_run_button.pressed.connect(_start_new_run)
	buttons.add_child(new_run_button)


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 72)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_stylebox_override("normal", _make_button_style(Color("466283")))
	button.add_theme_stylebox_override("hover", _make_button_style(Color("58779c")))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color("6f97c6")))
	return button


func _make_panel_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	return style


func _make_button_style(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = bg_color.lightened(0.2)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style
