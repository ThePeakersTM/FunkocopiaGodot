extends Node

static var native_cursor := true
static var downscroll := false

static var controller := false
static var ignore_mouse_until_ms := 0
static var controller_deadzone := 0.2

func ignore_mouse_briefly(ms: int = 100) -> void:
	ignore_mouse_until_ms = Time.get_ticks_msec() + ms

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		controller = true
	elif event is InputEventJoypadMotion:
		if abs(event.axis_value) > controller_deadzone:
			controller = true
	elif event is InputEventKey:
		controller = false
	elif event is InputEventMouseMotion:
		if Time.get_ticks_msec() >= ignore_mouse_until_ms:
			controller = false
