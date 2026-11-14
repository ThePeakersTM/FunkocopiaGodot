extends Overlay

@onready var on_off_button := $OnOffButton
@onready var button_sound := $OnOffButton/Sound

@onready var computer_boot := $ComputerStart

@onready var loading_screen := $ScreenElements/LoadingScreen
@onready var loading_bar := $ScreenElements/LoadingScreen/LoadingBar

@onready var accounts_screen := $ScreenElements/AccountsScreen
@onready var accounts := $ScreenElements/AccountsScreen/Accounts

var did_play_button_sound := false

var powered_on := false

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
	powered_on = false
	loading_screen.modulate = Color.TRANSPARENT
	loading_screen.visible = true
	accounts_screen.visible = false
	accounts.play("invis")

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
	super._ready()

func _process(delta: float) -> void:
	if not _plug_connected():
		_turn_off()
	if on_off_button.button_pressed:
		if not did_play_button_sound:
			button_sound.play()
		did_play_button_sound = true
	else:
		did_play_button_sound = false
	super._process(delta)
