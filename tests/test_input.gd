extends RefCounted

const InputScript = preload("res://scripts/game/game_input.gd")


func run() -> Dictionary:
	var failures: Array[String] = []
	var assertions: int = 0
	var action_name := &"test_move_up"

	assertions += 1
	if InputScript.direction_from_keycode(KEY_W) != Vector2i.UP:
		failures.append("W should map to up")

	assertions += 1
	if InputScript.direction_from_keycode(KEY_RIGHT) != Vector2i.RIGHT:
		failures.append("Right arrow should map to right")

	assertions += 1
	if InputScript.direction_from_joypad_button(JOY_BUTTON_DPAD_LEFT) != Vector2i.LEFT:
		failures.append("D-pad left should map to left")

	if InputMap.has_action(action_name):
		InputMap.erase_action(action_name)
	InputScript.configure_input_actions([
		{"action": action_name, "keycode": KEY_W, "button_index": JOY_BUTTON_DPAD_UP},
		{"action": action_name, "keycode": KEY_W, "button_index": JOY_BUTTON_DPAD_UP},
	])

	var key_events: int = 0
	var button_events: int = 0
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.keycode == KEY_W:
			key_events += 1
		if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_DPAD_UP:
			button_events += 1

	assertions += 1
	if key_events != 1:
		failures.append("duplicate keyboard bindings should not be added")

	assertions += 1
	if button_events != 1:
		failures.append("duplicate joypad bindings should not be added")

	if InputMap.has_action(action_name):
		InputMap.erase_action(action_name)
	return {
		"assertions": assertions,
		"failures": failures,
	}
