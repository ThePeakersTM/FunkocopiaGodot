extends Node

enum Mode {
	NORMAL,
	OBSERVE,
	INTERACT,
	SPEAK
}

const NORMAL   := Mode.NORMAL
const OBSERVE  := Mode.OBSERVE
const INTERACT := Mode.INTERACT
const SPEAK    := Mode.SPEAK

const ALL    := [NORMAL, OBSERVE, INTERACT, SPEAK]
const ALL_FUNCTIONAL := [OBSERVE, INTERACT, SPEAK]

func mode_to_string(mode: Mode) -> String:
	match mode:
		OBSERVE:  return "observe"
		INTERACT: return "interact"
		SPEAK:    return "speak"
		_:        return "normal"

func string_to_mode(string: String) -> Mode:
	match string:
		"observe":  return OBSERVE
		"interact": return INTERACT
		"speak":    return SPEAK
		_:          return NORMAL

func next_mode(mode: Mode) -> Mode:
	match mode:
		OBSERVE:  return INTERACT
		INTERACT: return SPEAK
		SPEAK:    return OBSERVE
		_:        return OBSERVE

const CURSOR_SPEED := 1100.0
var virtual_pos := Vector2.ZERO

const TRIGGER_PRESS := 0.5
const TRIGGER_RELEASE := 0.3

var newCursor: Sprite2D = null
var newCursor_native: Sprite2D = null
var newCursorPos: Vector2i = Vector2i(0, 0)

var textureMap: Dictionary[String, String] = {
	"normal":    "normal.png",
	"clickable": "clickable.png",
	"observe":   "observe.png",
	"interact":  "interact.png",
	"speak":     "speak.png"
}

var can_change_cursor := false
var current_mode := NORMAL
var _cached_textures: Dictionary[String, Texture2D] = {}

func get_cached_texture(path: String) -> Texture2D:
	if _cached_textures.has(path):
		return _cached_textures[path]
	else:
		var texture = load("res://assets/cursor/" + path)
		_cached_textures[path] = texture
		return texture

func _ready() -> void:
	if not Options.native_cursor:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	newCursor = Sprite2D.new()
	newCursor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	newCursor.texture = get_cached_texture(textureMap["normal"])
	newCursor.z_index = 4096
	newCursor.scale = Vector2(5, 5)
	newCursor.centered = false
	
	newCursor_native = Sprite2D.new()
	newCursor_native.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	newCursor_native.texture = get_cached_texture("native/" + textureMap["normal"])
	newCursor_native.z_index = 4096
	newCursor_native.scale = Vector2(5, 5)
	newCursor_native.centered = false
	
	if Options.native_cursor:
		add_child(newCursor_native)
	else:
		add_child(newCursor)

static func pixelate_movement(pos: Vector2, factor: Vector2) -> Vector2i:
	return Vector2i(
		floori(roundi(pos.x * factor.x) / factor.x),
		floori(roundi(pos.y * factor.y) / factor.y)
	)

var _held := {
	MOUSE_BUTTON_LEFT: false,
	MOUSE_BUTTON_RIGHT: false,
}

func _window_mouse_pos(view: Viewport) -> Vector2:
	var window_size := Vector2(view.get_window().size)
	var size_factor := view.get_visible_rect().size / window_size
	return view.get_mouse_position() / size_factor

func _send_click(view: Viewport, button: MouseButton, pressed: bool) -> void:
	_held[button] = pressed

	var mask := 0
	if _held[MOUSE_BUTTON_LEFT]:  mask |= MOUSE_BUTTON_MASK_LEFT
	if _held[MOUSE_BUTTON_RIGHT]: mask |= MOUSE_BUTTON_MASK_RIGHT

	var pos := _window_mouse_pos(view)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.pressed = pressed
	ev.button_mask = mask
	ev.position = pos
	ev.global_position = pos
	Input.parse_input_event(ev)

func _update_trigger(view: Viewport, button: MouseButton, axis: JoyAxis) -> void:
	var value := Input.get_joy_axis(0, axis)
	if not _held[button] and value > TRIGGER_PRESS:
		_send_click(view, button, true)
	elif _held[button] and value < TRIGGER_RELEASE:
		_send_click(view, button, false)

func _release_all(view: Viewport) -> void:
	for button in _held:
		if _held[button]:
			_send_click(view, button, false)

func _set_mouse_mode(mode: Input.MouseMode) -> void:
	if Input.mouse_mode == mode: return
	Options.ignore_mouse_briefly()
	Input.mouse_mode = mode

const POINTER_DEVICE_HINTS := ["wiimote", "wii remote", "nintendo rvl"]

static func has_pointer(device: int) -> bool:
	if not Input.get_connected_joypads().has(device):
		return false
	var joy_name := Input.get_joy_name(device).to_lower()
	for hint in POINTER_DEVICE_HINTS:
		if joy_name.contains(hint):
			return true
	return false

func _controller_movement(view: Viewport, delta: float) -> void:
	var window_size := Vector2(view.get_window().size)
	var size_factor := view.get_visible_rect().size / window_size

	var stick := Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	)
	var strength := stick.length()

	if strength < Options.controller_deadzone:
		virtual_pos = view.get_mouse_position() / size_factor
		return

	var t := (strength - Options.controller_deadzone) / (1.0 - Options.controller_deadzone)
	t *= t
	virtual_pos += (stick / strength) * t * CURSOR_SPEED * delta
	virtual_pos = virtual_pos.clamp(Vector2.ZERO, window_size - Vector2.ONE)

	Options.ignore_mouse_briefly()
	if has_pointer(0):
		virtual_pos = stick * window_size
	
	Input.warp_mouse(virtual_pos)

func _process(delta: float) -> void:
	var view := get_viewport()
	if view == null: return

	if Options.controller:
		_set_mouse_mode(Input.MOUSE_MODE_CONFINED)
		_controller_movement(view, delta)
		_update_trigger(view, MOUSE_BUTTON_LEFT,  JOY_AXIS_TRIGGER_LEFT )
		_update_trigger(view, MOUSE_BUTTON_RIGHT, JOY_AXIS_TRIGGER_RIGHT)
	else:
		_release_all(view)
		_set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if not Options.native_cursor:
		_set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	if Input.is_action_just_pressed("right_click"):
		if can_change_cursor:
			current_mode = next_mode(current_mode)
	
	var cam := view.get_camera_2d()
	if cam == null: return
	
	var tp := ""
	
	if can_change_cursor:
		tp = textureMap[mode_to_string(current_mode)]
	else:
		tp = textureMap[
			"clickable" if DisplayServer.cursor_get_shape() == DisplayServer.CURSOR_POINTING_HAND else
			"normal"
		]
	
	newCursor.texture = get_cached_texture(tp)
	newCursor_native.texture = get_cached_texture("native/" + tp)
	
	if cam == null: return
	newCursorPos = view.get_mouse_position().snapped(
		newCursor.scale
	) + cam.position
	if cam.anchor_mode == Camera2D.AnchorMode.ANCHOR_MODE_DRAG_CENTER:
		newCursorPos -= Vector2i(960, 540)
	if newCursor != null:
		newCursor.position.x = newCursorPos.x
		newCursor.position.y = newCursorPos.y
	if newCursor_native != null:
		newCursor_native.position.x = newCursorPos.x
		newCursor_native.position.y = newCursorPos.y
