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

#region double press
var _double_press_timers: Dictionary[String, int] = {}
var _double_press_times: Dictionary[String, int] = {}

func double_pressed(key: StringName) -> bool:
	if not _double_press_timers.has(key):
		_double_press_timers[key] = Time.get_ticks_msec()
	if not _double_press_times.has(key):
		_double_press_times[key] = 0
	
	if Input.is_action_just_pressed(key):
		var time := Time.get_ticks_msec() - _double_press_timers[key]
		if time < 500:
			_double_press_times[key] += 1
			if _double_press_times[key] == 2:
				return true
		else:
			_double_press_times[key] = 1
		_double_press_timers[key] = Time.get_ticks_msec()
	return false
#endregion
#region DAS
const initial_das_delay := 0.5
const das_repeat_rate := 0.05

var _das_repeat_timers: Dictionary[String, float] = {}
var _das_check_for_repeat: Dictionary[String, bool] = {}

func das(key: StringName) -> bool:
	if not _das_repeat_timers.has(key):
		_das_repeat_timers[key] = initial_das_delay
	if not _das_check_for_repeat.has(key):
		_das_check_for_repeat[key] = true
	return _das_check_for_repeat[key]

func update_das(delta: float) -> void:
	for key in _das_check_for_repeat.keys():
		_das_check_for_repeat[key] = false
		
		if Input.is_action_just_pressed(key):
			_das_check_for_repeat[key] = true
			_das_repeat_timers[key] = initial_das_delay
		
		elif Input.is_action_pressed(key):
			_das_repeat_timers[key] -= delta
			if _das_repeat_timers[key] <= 0.0:
				_das_check_for_repeat[key] = true
				_das_repeat_timers[key] = das_repeat_rate
#endregion

var _last_delta := 0.0

func _process(delta: float) -> void:
	update_das(delta)
	_last_delta = delta
