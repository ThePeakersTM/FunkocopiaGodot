extends Node

const CURSOR_SPEED := 1100.0
var virtual_pos := Vector2.ZERO

const TRIGGER_PRESS := 0.5
const TRIGGER_RELEASE := 0.3

var newCursor: Sprite2D = null
var newCursorPos: Vector2i = Vector2i(0, 0)

var textureMap: Dictionary[String, Texture2D] = {
	"normal":    load("res://assets/cursor/normal.png"),
	"clickable": load("res://assets/cursor/clickable.png"),
	"observe":   load("res://assets/cursor/observe.png"),
	"interact":  load("res://assets/cursor/interact.png"),
	"speak":     load("res://assets/cursor/speak.png")
}

func _ready() -> void:
	if not Options.native_cursor:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	newCursor = Sprite2D.new()
	newCursor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	newCursor.texture = textureMap["normal"]
	newCursor.z_index = 4096
	newCursor.scale = Vector2(7.5, 7.5)
	newCursor.centered = false
	if not Options.native_cursor:
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
	var cam := view.get_camera_2d()
	if cam == null: return
	
	newCursor.texture = textureMap[
		"clickable" if DisplayServer.cursor_get_shape() == DisplayServer.CURSOR_POINTING_HAND else
		"normal"
	]
	
	if cam == null: return
	newCursorPos = view.get_mouse_position().snapped(
		newCursor.scale
	) + cam.position + Vector2(960, 540)
	if newCursor != null:
		if newCursor.position != null:
			newCursor.position.x = newCursorPos.x
			newCursor.position.y = newCursorPos.y
