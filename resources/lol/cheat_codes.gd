extends Node

@onready var COMMAND_INPUT: LineEdit = $Control/LineEdit
@onready var message := $Control/Message

@onready var control := $Control

const COMMANDS: Array = [
	"michael",
]

func _ready() -> void:
	COMMAND_INPUT.hide()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("cheat_codes"):
		COMMAND_INPUT.show()
	
	var view = get_viewport()
	if view == null: return
	var cam = view.get_camera_2d()
	if cam == null: return
	control.position = cam.position
	if cam.anchor_mode == cam.ANCHOR_MODE_DRAG_CENTER:
		control.position -= Vector2(960, 540)

func _on_line_edit_text_changed(new_text: String) -> void:
	var is_command_recognised: bool = check_command_text(new_text)
	if is_command_recognised:
		COMMAND_INPUT.hide()
		COMMAND_INPUT.clear()
		implement_user_command(new_text)

func check_command_text(user_input: String) -> bool:
	for command_word: String in COMMANDS:
		if user_input.to_lower() == command_word.to_lower():
			return true
	return false

func implement_user_command(command: String) -> void:
	var command_failed = false
	message.modulate = Color(1, 1, 1, 0.5)
	match command:
		"michael":
			if not has_node("/root/GameState"):
				command_failed = true
			else:
				var player = get_node("/root/GameState/Bfellow")
				player.moonwalk = not player.moonwalk
				message.text = ("Activating" if player.moonwalk else "Disabling") + " moonwalking."
	if command_failed:
		message.modulate = Color(1, 0, 0, 0.5)
		message.text = "Failed to run command \"" + command + "\""
	
	get_tree().create_timer(1).timeout.connect(func():
		create_tween().tween_method(
			func(value: float):
				if command_failed:
					message.modulate = Color(1, 0, 0, value)
				else:
					message.modulate = Color(1, 1, 1, value),
			0.5,
			0,
			1
		)
	)
