extends Node2D

const MazeGeneratorScript = preload("res://scripts/maze_generator.gd")
const TEXT_COLOR := Color("f5f7fb")
const TOP_HUD_HEIGHT := 112.0
const BOTTOM_HUD_HEIGHT := 110.0
const OUTER_MARGIN := 28.0
const AUTO_ADVANCE_SECONDS := 2.8

var run_seed := 0
var level := 1
var maze_width := 0
var maze_height := 0
var level_seed := 0
var cells: Array[PackedInt32Array] = []
var start_cell := Vector2i.ZERO
var goal_cell := Vector2i.ZERO
var player_cell := Vector2i.ZERO
var solution_path: Array[Vector2i] = []
var optimal_steps := 0
var player_steps := 0
var level_retries := 0
var completed := false
var pulse_time := 0.0

var background_color := Color("101826")
var playfield_color := Color("162233")
var wall_color := Color("4d6685")
var node_color := Color("d8e4f4")
var start_color := Color("5fd08c")
var goal_color := Color("ffcc66")
var player_color := Color("73d2ff")
var panel_color := Color("203147")
var panel_border_color := Color("314864")
var button_color := Color("466283")
var button_hover_color := Color("58779c")
var button_pressed_color := Color("6f97c6")
var star_dim_color := Color("6d5a2f")

var maze_label: Label
var score_label: Label
var retry_button: Button
var new_run_button: Button
var top_panel: PanelContainer
var bottom_panel: PanelContainer
var splash_panel: PanelContainer
var splash_title_label: Label
var splash_score_label: Label
var splash_optimal_label: Label
var splash_retries_label: Label
var splash_stars_label: Label
var splash_caption_label: Label
var advance_timer: Timer


func _ready() -> void:
	randomize()
	_apply_palette(level)
	_build_ui()
	_build_advance_timer()
	_start_new_run()


func _process(delta: float) -> void:
	pulse_time += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if completed:
		return

	if event is InputEventScreenTouch and event.pressed:
		_handle_maze_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_maze_tap(event.position)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), background_color, true)

	if maze_width <= 0 or maze_height <= 0:
		return

	var draw_area := _get_draw_area()
	draw_rect(draw_area, playfield_color, true)

	var cell_size := _get_cell_size()
	var origin := _get_grid_origin(cell_size)
	var wall_width := clampf(cell_size * 0.1, 3.0, 10.0)
	var node_radius := clampf(cell_size * 0.085, 3.0, 7.0)
	var marker_radius := clampf(cell_size * 0.18, 7.0, 16.0)
	var pulse := 0.84 + 0.16 * sin(pulse_time * 4.0)

	for y in range(maze_height):
		for x in range(maze_width):
			var cell := Vector2i(x, y)
			var cell_origin := origin + Vector2(x, y) * cell_size
			var top_left := cell_origin
			var top_right := cell_origin + Vector2(cell_size, 0.0)
			var bottom_left := cell_origin + Vector2(0.0, cell_size)
			var bottom_right := cell_origin + Vector2(cell_size, cell_size)

			if y == 0:
				draw_line(top_left, top_right, wall_color, wall_width)
			if x == 0:
				draw_line(top_left, bottom_left, wall_color, wall_width)
			if not MazeGeneratorScript.has_connection(cells, cell, Vector2i.RIGHT):
				draw_line(top_right, bottom_right, wall_color, wall_width)
			if not MazeGeneratorScript.has_connection(cells, cell, Vector2i.DOWN):
				draw_line(bottom_left, bottom_right, wall_color, wall_width)

	for y in range(maze_height):
		for x in range(maze_width):
			draw_circle(_cell_to_screen(Vector2i(x, y)), node_radius, node_color)

	draw_circle(_cell_to_screen(start_cell), marker_radius * 0.8, start_color)
	draw_circle(_cell_to_screen(goal_cell), marker_radius * 0.95, goal_color)
	draw_arc(
		_cell_to_screen(goal_cell),
		marker_radius + 7.0 + pulse * 3.5,
		0.0,
		TAU,
		48,
		goal_color.lightened(0.18),
		3.0
	)

	draw_circle(_cell_to_screen(player_cell), marker_radius, player_color)
	draw_arc(
		_cell_to_screen(player_cell),
		marker_radius + 7.0 + pulse * 3.5,
		0.0,
		TAU,
		48,
		player_color.lightened(0.15),
		3.0
	)


func _start_new_run() -> void:
	run_seed = randi()
	level = 1
	level_retries = 0
	_generate_level()


func _restart_level() -> void:
	level_retries += 1
	_generate_level()


func _generate_level() -> void:
	advance_timer.stop()
	completed = false
	_set_splash_visible(false)

	var dimensions := _get_level_dimensions(level)
	maze_width = dimensions.x
	maze_height = dimensions.y
	level_seed = abs(hash([run_seed, level, maze_width, maze_height]))
	if level_seed == 0:
		level_seed = 1

	_apply_palette(level)

	var maze: Dictionary = MazeGeneratorScript.generate(maze_width, maze_height, level_seed)
	cells = maze["cells"]
	start_cell = maze["start"]
	goal_cell = maze["goal"]
	player_cell = start_cell
	solution_path = maze["solution_path"]
	optimal_steps = maze["solution_length"]
	player_steps = 0
	_update_ui()
	queue_redraw()


func _get_level_dimensions(current_level: int) -> Vector2i:
	var width := 5 + int((current_level - 1) / 2)
	var height := 5 + int((current_level - 1) / 3)
	return Vector2i(width, height)


func _handle_maze_tap(screen_position: Vector2) -> void:
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
	player_cell = target_cell
	player_steps += 1

	if player_cell == goal_cell:
		_complete_level()
	else:
		_update_ui()

	queue_redraw()


func _complete_level() -> void:
	completed = true
	_update_ui()
	_update_completion_splash()
	advance_timer.start(AUTO_ADVANCE_SECONDS)


func _advance_to_next_level() -> void:
	if not completed:
		return

	level += 1
	level_retries = 0
	_generate_level()


func _update_ui() -> void:
	maze_label.text = "Maze %d" % level
	score_label.text = "Score %d" % player_steps


func _update_completion_splash() -> void:
	var stars := _calculate_star_rating()
	splash_title_label.text = "Maze %d cleared" % level
	splash_score_label.text = "Player score: %d" % player_steps
	splash_optimal_label.text = "Optimal score: %d" % optimal_steps
	splash_retries_label.text = "Retries: %d" % level_retries
	splash_stars_label.text = _build_star_string(stars)
	splash_stars_label.add_theme_color_override("font_color", goal_color)
	splash_caption_label.text = _get_star_caption(stars)
	_set_splash_visible(true)


func _calculate_star_rating() -> int:
	if optimal_steps <= 0:
		return 3
	if player_steps == optimal_steps:
		return 3

	var two_star_limit := int(ceili(float(optimal_steps) * 1.25))
	if player_steps <= two_star_limit and level_retries <= 1:
		return 2

	return 1


func _build_star_string(stars: int) -> String:
	var segments: Array[String] = []

	for index in range(3):
		if index < stars:
			segments.append("★")
		else:
			segments.append("☆")

	return " ".join(segments)


func _get_star_caption(stars: int) -> String:
	match stars:
		3:
			return "Perfect route."
		2:
			return "Strong run."
		_:
			return "Maze complete."


func _get_draw_area() -> Rect2:
	var viewport_size := get_viewport_rect().size
	return Rect2(
		Vector2(OUTER_MARGIN, TOP_HUD_HEIGHT),
		viewport_size - Vector2(OUTER_MARGIN * 2.0, TOP_HUD_HEIGHT + BOTTOM_HUD_HEIGHT)
	)


func _get_cell_size() -> float:
	var draw_area := _get_draw_area()
	return minf(draw_area.size.x / float(maze_width), draw_area.size.y / float(maze_height))


func _get_grid_origin(cell_size: float) -> Vector2:
	var draw_area := _get_draw_area()
	var grid_size := Vector2(maze_width, maze_height) * cell_size
	return draw_area.position + (draw_area.size - grid_size) * 0.5


func _cell_to_screen(cell: Vector2i) -> Vector2:
	var cell_size := _get_cell_size()
	return _get_grid_origin(cell_size) + (Vector2(cell.x, cell.y) + Vector2.ONE * 0.5) * cell_size


func _get_tap_radius() -> float:
	return maxf(_get_cell_size() * 0.28, 28.0)


func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)

	top_panel = PanelContainer.new()
	top_panel.anchor_right = 1.0
	top_panel.offset_left = 16.0
	top_panel.offset_top = 16.0
	top_panel.offset_right = -16.0
	top_panel.offset_bottom = TOP_HUD_HEIGHT - 16.0
	ui.add_child(top_panel)

	var top_content := HBoxContainer.new()
	top_content.alignment = BoxContainer.ALIGNMENT_CENTER
	top_content.add_theme_constant_override("separation", 24)
	top_panel.add_child(top_content)

	maze_label = Label.new()
	maze_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	maze_label.add_theme_font_size_override("font_size", 34)
	maze_label.add_theme_color_override("font_color", TEXT_COLOR)
	top_content.add_child(maze_label)

	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.add_theme_font_size_override("font_size", 34)
	score_label.add_theme_color_override("font_color", TEXT_COLOR)
	top_content.add_child(score_label)

	bottom_panel = PanelContainer.new()
	bottom_panel.anchor_top = 1.0
	bottom_panel.anchor_right = 1.0
	bottom_panel.anchor_bottom = 1.0
	bottom_panel.offset_left = 16.0
	bottom_panel.offset_top = -BOTTOM_HUD_HEIGHT + 16.0
	bottom_panel.offset_right = -16.0
	bottom_panel.offset_bottom = -16.0
	ui.add_child(bottom_panel)

	var bottom_content := HBoxContainer.new()
	bottom_content.add_theme_constant_override("separation", 12)
	bottom_panel.add_child(bottom_content)

	retry_button = _make_button("Retry current maze")
	retry_button.pressed.connect(_restart_level)
	bottom_content.add_child(retry_button)

	new_run_button = _make_button("Start a new run")
	new_run_button.pressed.connect(_start_new_run)
	bottom_content.add_child(new_run_button)

	splash_panel = PanelContainer.new()
	splash_panel.anchor_left = 0.5
	splash_panel.anchor_top = 0.5
	splash_panel.anchor_right = 0.5
	splash_panel.anchor_bottom = 0.5
	splash_panel.offset_left = -220.0
	splash_panel.offset_top = -210.0
	splash_panel.offset_right = 220.0
	splash_panel.offset_bottom = 210.0
	splash_panel.visible = false
	ui.add_child(splash_panel)

	var splash_content := VBoxContainer.new()
	splash_content.add_theme_constant_override("separation", 12)
	splash_panel.add_child(splash_content)

	splash_title_label = Label.new()
	splash_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash_title_label.add_theme_font_size_override("font_size", 36)
	splash_title_label.add_theme_color_override("font_color", TEXT_COLOR)
	splash_content.add_child(splash_title_label)

	splash_score_label = _make_splash_stat_label()
	splash_content.add_child(splash_score_label)

	splash_optimal_label = _make_splash_stat_label()
	splash_content.add_child(splash_optimal_label)

	splash_retries_label = _make_splash_stat_label()
	splash_content.add_child(splash_retries_label)

	splash_stars_label = Label.new()
	splash_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash_stars_label.add_theme_font_size_override("font_size", 42)
	splash_content.add_child(splash_stars_label)

	splash_caption_label = Label.new()
	splash_caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash_caption_label.add_theme_font_size_override("font_size", 24)
	splash_caption_label.add_theme_color_override("font_color", TEXT_COLOR)
	splash_content.add_child(splash_caption_label)

	_apply_palette_to_ui()


func _build_advance_timer() -> void:
	advance_timer = Timer.new()
	advance_timer.one_shot = true
	advance_timer.timeout.connect(_advance_to_next_level)
	add_child(advance_timer)


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 66)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	return button


func _make_splash_stat_label() -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	return label


func _apply_palette(level_value: int) -> void:
	var difficulty := clampf(float(level_value - 1) / 14.0, 0.0, 1.0)
	background_color = Color.from_hsv(0.61 - 0.05 * difficulty, 0.45, 0.12 + 0.02 * difficulty)
	playfield_color = Color.from_hsv(0.6 - 0.04 * difficulty, 0.34 + 0.06 * difficulty, 0.2 + 0.03 * difficulty)
	wall_color = Color.from_hsv(0.57 - 0.08 * difficulty, 0.3 + 0.16 * difficulty, 0.82 - 0.08 * difficulty)
	node_color = Color.from_hsv(0.58 - 0.03 * difficulty, 0.08 + 0.05 * difficulty, 0.93)
	start_color = Color.from_hsv(0.37 - 0.03 * difficulty, 0.52, 0.88)
	goal_color = Color.from_hsv(0.12 - 0.03 * difficulty, 0.62, 0.96)
	player_color = Color.from_hsv(0.53 - 0.05 * difficulty, 0.48, 0.95)
	panel_color = playfield_color.lightened(0.08)
	panel_border_color = wall_color.lightened(0.12)
	button_color = wall_color.darkened(0.18)
	button_hover_color = wall_color.darkened(0.06)
	button_pressed_color = player_color.darkened(0.08)
	star_dim_color = goal_color.darkened(0.55)
	_apply_palette_to_ui()


func _apply_palette_to_ui() -> void:
	if top_panel == null:
		return

	top_panel.add_theme_stylebox_override("panel", _make_panel_style(panel_color, panel_border_color))
	bottom_panel.add_theme_stylebox_override("panel", _make_panel_style(panel_color, panel_border_color))
	splash_panel.add_theme_stylebox_override("panel", _make_panel_style(panel_color.lightened(0.04), panel_border_color.lightened(0.08)))
	retry_button.add_theme_stylebox_override("normal", _make_button_style(button_color))
	retry_button.add_theme_stylebox_override("hover", _make_button_style(button_hover_color))
	retry_button.add_theme_stylebox_override("pressed", _make_button_style(button_pressed_color))
	new_run_button.add_theme_stylebox_override("normal", _make_button_style(button_color))
	new_run_button.add_theme_stylebox_override("hover", _make_button_style(button_hover_color))
	new_run_button.add_theme_stylebox_override("pressed", _make_button_style(button_pressed_color))


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
	style.border_color = bg_color.lightened(0.16)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style


func _set_splash_visible(is_visible: bool) -> void:
	splash_panel.visible = is_visible
