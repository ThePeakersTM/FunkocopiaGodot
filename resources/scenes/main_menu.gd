extends AnimatedSprite2D

@onready var button_list := $FullRect/PaperPart
@onready var new_button := $FullRect/PaperPart/NewButton
@onready var continue_button := $FullRect/PaperPart/ContinueButton
@onready var quit_button := $FullRect/PaperPart/QuitButton
@onready var handle := $FullRect/PaperPart/Handle
@onready var sfx := $PaperAppear

var has := false

var touching_handle := false

func _ready() -> void:
	button_list.hide()
	frame = 0
	new_button.pressed.connect(func():
		BaldiTransition.change_scene("res://resources/scenes/game/game_state.tscn")
	)
	quit_button.pressed.connect(func():
		quit_button.texture_pressed = quit_button.texture_hover
		quit_button.texture_normal = quit_button.texture_hover
		get_tree().create_timer(2).timeout.connect(func():
			get_tree().quit()
		)
		get_tree().paused = true
	)

	
	handle.mouse_entered.connect(func(): touching_handle = true )
	handle.mouse_exited.connect( func(): touching_handle = false)

var holding_handle := false
var hold_offset: int

func do_menu_shit() -> void:
	show()
	play("default")
	sfx.play()

func _process(_delta: float) -> void:
	if frame == 5 and (not has):
		button_list.show()
		has = true
	
	if Input.is_action_pressed("left_click") or holding_handle:
		if not holding_handle:
			if touching_handle:
				hold_offset = Cursor.newCursorPos.x - round(handle.global_position.x)
				holding_handle = true
		
		if holding_handle:
			handle.global_position.x = clampi(
				round(Cursor.newCursorPos.x - hold_offset),
				-835,
				-265
			)
			var calcx = (835 - (-handle.global_position.x)) / 520
			AudioServer.set_bus_volume_linear(0, calcx)
			
			if not Input.is_action_pressed("left_click"):
				holding_handle = false
	
	if continue_button.mouse_filter == Control.MOUSE_FILTER_STOP and continue_button.disabled:
		continue_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	elif not continue_button.disabled:
		continue_button.mouse_filter = Control.MOUSE_FILTER_STOP
