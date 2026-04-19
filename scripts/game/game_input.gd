extends RefCounted
class_name MazePointInput

static func direction_from_keycode(keycode: Key) -> Vector2i:
	match keycode:
		KEY_UP, KEY_W:
			return Vector2i.UP
		KEY_RIGHT, KEY_D:
			return Vector2i.RIGHT
		KEY_DOWN, KEY_S:
			return Vector2i.DOWN
		KEY_LEFT, KEY_A:
			return Vector2i.LEFT
		_:
			return Vector2i.ZERO


static func direction_from_joypad_button(button_index: JoyButton) -> Vector2i:
	match button_index:
		JOY_BUTTON_DPAD_UP:
			return Vector2i.UP
		JOY_BUTTON_DPAD_RIGHT:
			return Vector2i.RIGHT
		JOY_BUTTON_DPAD_DOWN:
			return Vector2i.DOWN
		JOY_BUTTON_DPAD_LEFT:
			return Vector2i.LEFT
		_:
			return Vector2i.ZERO


static func configure_input_actions(bindings: Array[Dictionary]) -> void:
	for binding_variant in bindings:
		var binding: Dictionary = binding_variant
		var action_name: StringName = StringName(binding.get("action", ""))
		if action_name.is_empty():
			continue
		if binding.has("keycode"):
			ensure_key_action(action_name, int(binding["keycode"]))
		if binding.has("button_index"):
			ensure_joypad_action(action_name, int(binding["button_index"]))


static func ensure_key_action(action_name: StringName, keycode: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for existing_event in InputMap.action_get_events(action_name):
		if existing_event is InputEventKey and existing_event.keycode == keycode:
			return
	var key_event: InputEventKey = InputEventKey.new()
	key_event.keycode = keycode
	InputMap.action_add_event(action_name, key_event)


static func ensure_joypad_action(action_name: StringName, button_index: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for existing_event in InputMap.action_get_events(action_name):
		if existing_event is InputEventJoypadButton and existing_event.button_index == button_index:
			return
	var button_event: InputEventJoypadButton = InputEventJoypadButton.new()
	button_event.button_index = button_index
	InputMap.action_add_event(action_name, button_event)
