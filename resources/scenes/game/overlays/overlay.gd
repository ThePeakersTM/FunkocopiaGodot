extends Sprite2D
class_name Overlay

@export var custom_id := "overlay"
@export var leave_rect := Rect2i(0, 0, 20, 20)

var leave_interaction: Control

var touching_leave := false

func _ready() -> void:
	leave_interaction = Control.new()
	leave_interaction.position = leave_rect.position
	leave_interaction.size = leave_rect.size
	leave_interaction.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_child(leave_interaction)
	
	leave_interaction.mouse_entered.connect(func(): touching_leave = true )
	leave_interaction.mouse_exited.connect( func(): touching_leave = false)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("left_click"):
		if touching_leave:
			get_parent().get_parent().on_hide_ui(custom_id)
			hide()
			queue_free()
