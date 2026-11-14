extends Overlay

@onready var on_off_button := $OnOffButton
@onready var button_sound := $OnOffButton/Sound

@onready var computer_boot := $ComputerStart

var did_play_button_sound := false

var powered_on := false

func _plug_connected() -> bool:
	return room.plug.modulate.a < 1

func _turn_on() -> void:
	computer_boot.play()

func _turn_off() -> void:
	pass

func _ready() -> void:
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
