extends Overlay

@onready var on_off_button := $OnOffButton
@onready var button_sound := $OnOffButton/Sound

@onready var computer_boot := $ComputerStart

@onready var loading_screen := $ScreenElements/LoadingScreen
@onready var loading_bar := $ScreenElements/LoadingScreen/LoadingBar

@onready var accounts_screen := $ScreenElements/AccountsScreen
@onready var accounts := $ScreenElements/AccountsScreen/Accounts

@onready var desktop_screen := $ScreenElements/DesktopScreen

var did_play_button_sound := false

var powered_on := false

var double_press_timers: Dictionary[String, int] = {}
var double_press_times: Dictionary[String, int] = {}

func double_pressed(key: StringName) -> bool:
	if not double_press_timers.has(key):
		double_press_timers[key] = Time.get_ticks_msec()
	if not double_press_times.has(key):
		double_press_times[key] = 0
	
	if Input.is_action_just_pressed(key):
		var time := Time.get_ticks_msec() - double_press_timers[key]
		if time < 500:
			double_press_times[key] += 1
			if double_press_times[key] == 2:
				return true
		else:
			double_press_times[key] = 0
		double_press_timers[key] = Time.get_ticks_msec()
	return false

func _plug_connected() -> bool:
	return room.plug.modulate.a < 1

func _turn_on() -> void:
	computer_boot.play()
	loading_bar.visible = false
	create_tween().tween_method(
		func(val): loading_screen.modulate = Color(1, 1, 1, val),
		0.0,
		1.0,
		0.75
	).finished.connect(func():
		get_tree().create_timer(0.5).timeout.connect(func():
			loading_bar.visible = true
			create_tween().tween_method(
				func(val):
					loading_bar.position = Vector2(45 + ((val % 10) * 8), 104),
				0,
				26,
				2.7
			).finished.connect(func():
				get_tree().create_timer(1).timeout.connect(func():
					loading_screen.modulate = Color.TRANSPARENT
					get_tree().create_timer(0.5).timeout.connect(func():
						accounts_screen.visible = true
						accounts.play("appear")
					)
				)
			)
		)
	)

func _turn_off() -> void:
	powered_on              = false
	loading_screen.modulate = Color.TRANSPARENT
	loading_screen.visible  = true
	accounts_screen.visible = false
	desktop_screen.visible  = false
	accounts.play("invis")

func _on_open_app(app_name: String) -> void:
	var app_name_ext := app_name.rsplit(".")
	var app_ext := "" if app_name_ext.size() == 1 else app_name_ext[1]
	var app_no_ext := app_name if app_name_ext.size() == 1 else app_name_ext[0]
	print(
		"Opened app with name \"%s\". Extension: \"%s\", filename without extension: \"%s\"" % [
			app_name,
			app_ext,
			app_no_ext
		]
	)

func _ready() -> void:
	_turn_off()
	on_off_button.pressed.connect(func():
		if _plug_connected():
			powered_on = not powered_on
			if powered_on:
				_turn_on()
			else:
				_turn_off()
	)
	accounts.get_node("Bfellow").pressed.connect(func():
		if accounts.animation == "idle":
			accounts.play("disappear")
	)
	accounts.get_node("Henry").pressed.connect(func():
		if accounts.animation == "idle":
			accounts.play("henry")
			accounts.get_node("Sound").play()
	)
	var desktop_icons = desktop_screen.get_node("Elements").get_children()
	for icon: TextureButton in desktop_icons:
		icon.pressed.connect(func():
			if double_pressed("left_click"):
				_on_open_app(icon.name.replace("#", "."))
		)
	super._ready()

const ICON_SUMMON_DELAY := 0.25
const ICON_FOR_EACH_DELAY := 0.125

func _show_desktop() -> void:
	desktop_screen.visible  = true
	var desktop_icons = desktop_screen.get_node("Elements").get_children()
	for i in desktop_icons.size():
		var icon: TextureButton = desktop_icons[i]
		icon.visible = false
		get_tree().create_timer(ICON_SUMMON_DELAY + (ICON_FOR_EACH_DELAY * i)).timeout.connect(func():
			icon.visible = true
		)

func _process(delta: float) -> void:
	if not _plug_connected():
		_turn_off()
	if on_off_button.button_pressed:
		if not did_play_button_sound:
			button_sound.play()
		did_play_button_sound = true
	else:
		did_play_button_sound = false
	if (
		accounts.frame == 2 and accounts.animation == "appear"
	) or (
		accounts.frame == 5 and accounts.animation == "henry"
	):
		accounts.play("idle")
	if accounts.frame == 3 and accounts.animation == "disappear" and accounts_screen.visible:
		accounts_screen.visible = false
		_show_desktop()
	super._process(delta)
