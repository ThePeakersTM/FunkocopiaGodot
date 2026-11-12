extends Node2D
class_name Room

@export var id := "room_id"
@export var title := "Room Name"

@export_subgroup("Can Camera Move", "can_move_")
@export var can_move_x_axis = true
@export var can_move_y_axis = true
@export_group("")
@export var player: TopDownCharacter2D

func set_mouse_mode(control: Control, valid: Array[Cursor.Mode] = Cursor.ALL_FUNCTIONAL_MODES, custom_shape: Control.CursorShape = Control.CURSOR_POINTING_HAND):
	if Cursor.current_mode in valid:
		control.mouse_default_cursor_shape = custom_shape
	else:
		control.mouse_default_cursor_shape = Control.CURSOR_ARROW

func load_overlay(overlay: String) -> void:
	get_parent().load_overlay(overlay)

func show_ui(ui: String) -> void:
	get_parent().on_show_ui(ui)
